{-
    Модуль, отвечающий за работу с тематическими тегами и с именами авторов статей.
    https://github.com/ruHaskell/ruhaskell
    Все права принадлежат русскоязычному сообществу Haskell-разработчиков, 2015-2016 г.
-}

{-# LANGUAGE OverloadedStrings #-}

module Tags (
      buildPostsTags
    , buildPostsAuthors
    , buildPostsCategories
    , createPageWithAllTags
    , createPageWithAllAuthors
    , createPageWithAllCategories
    , convertTagsToLinks
    , convertCategoriesToLinks
    , convertAuthorsToLinks
) where


import           Control.Monad.Reader
import           Data.List (intercalate, isInfixOf)
import           Hakyll
import           Text.Blaze.Html (toValue, (!))
import           Text.Blaze.Html.Renderer.String (renderHtml)
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A

import           Context (postContext)
import           Markup.Authors (authorsTemplate)
import           Markup.Categories (categoriesTemplate)
import           Markup.Default (defaultTemplate)
import           Markup.Posts (postsTemplate)
import           Markup.Tags (tagsTemplate)
import           Misc (TagsAndAuthors, TagsReader, getNameOfAuthor,
                       getRussianNameOfCategory)


-- Функция извлекает из всех статей значения поля tags и собирает их в кучу.
buildPostsTags :: MonadMetadata m => m Tags
buildPostsTags = buildTags "posts/**" $ fromCapture "tags/*.html"

-- Функция определяет категорию, к которой относится статья.
buildPostsCategories :: MonadMetadata m => m Tags
buildPostsCategories = buildCategories "posts/**" $ fromCapture "categories/*.html"

-- Функция извлекает из всех статей значения поля author и собирает их в кучу.
buildPostsAuthors :: (MonadMetadata m, MonadFail m) => m Tags
buildPostsAuthors = buildTagsWith getNameOfAuthor "posts/**" $ fromCapture "authors/*.html"

-- Функция отрисовывает тег-ссылку вместе со значком, отражающим количество публикаций,
-- соответствующих данному тегу. Например, количество статей данного автора.
-- За основу взяты исходники Hakyll.
createTagLinkWithBadge :: Double
                       -> Double
                       -> String
                       -> String
                       -> Int
                       -> Int
                       -> Int
                       -> String
createTagLinkWithBadge = createGenericTagLinkWithBadge id

-- Отрисовываем тег для категории, с заменой родного английского названия русским аналогом.
createRussianTagLinkWithBadge :: Double
                              -> Double
                              -> String
                              -> String
                              -> Int
                              -> Int
                              -> Int
                              -> String
createRussianTagLinkWithBadge = createGenericTagLinkWithBadge getRussianNameOfCategory

createGenericTagLinkWithBadge :: (String -> String)
                              -> Double
                              -> Double
                              -> String
                              -> String
                              -> Int
                              -> Int
                              -> Int
                              -> String
{-# INLINE createGenericTagLinkWithBadge #-}
createGenericTagLinkWithBadge convert
                              smallestFontSizeInPercent
                              biggestFontSizeInPercent
                              tag
                              url
                              count
                              min'
                              max' =
    let diff     = 1 + fromIntegral max' - fromIntegral min'
        relative = (fromIntegral count - fromIntegral min') / diff
        size     = floor $ smallestFontSizeInPercent + relative * (biggestFontSizeInPercent - smallestFontSizeInPercent) :: Int
    in renderHtml $ do
        -- Формируем стандартный тег <a href...>
        H.a ! A.style (toValue $ "font-size: " ++ show size ++ "%")
            ! A.href (toValue url) $
            H.preEscapedToHtml $ convert tag
        H.span ! A.style (toValue $ "font-size: " ++ show size ++ "%") $
            H.preEscapedToHtml $ "&nbsp;<span class=\"tag tag-default\">" ++ show count ++ "</span>"

-- Отрисовываем облако с тегами-ссылками, имеющими количественные значки.
renderTagCloudWithBadges :: Double
                         -> Double
                         -> Tags
                         -> Bool
                         -> Compiler String
renderTagCloudWithBadges smallestFontSizeInPercent
                         biggestFontSizeInPercent
                         specificTags
                         thisIsCategoriesCloud =
    renderTagCloudWith tagLinkRenderer
                       concatenateLinksWithSpaces
                       smallestFontSizeInPercent
                       biggestFontSizeInPercent
                       specificTags
  where
    tagLinkRenderer = if thisIsCategoriesCloud
                        then createRussianTagLinkWithBadge
                        else createTagLinkWithBadge
    concatenateLinksWithSpaces = intercalate "<span style=\"padding-left: 20px;\"></span>"

-- Вспомогательная функция, формирующая страницу с облаком определённых тегов.
createPageWithTagsCloud :: Tags
                        -> Identifier
                        -> Double
                        -> Double
                        -> String
                        -> String
                        -> Compiler Template
                        -> Rules ()
createPageWithTagsCloud specificTags
                        pageWithSpecificTags
                        smallestFontSizeInPercent
                        biggestFontSizeInPercent
                        pageTitle
                        cloudName
                        specificTemplate =
    create [pageWithSpecificTags] $ do
        route idRoute
        compile $ do
            let renderedCloud _ = renderTagCloudWithBadges smallestFontSizeInPercent
                                                           biggestFontSizeInPercent
                                                           specificTags
                                                           ("Разделы" `isInfixOf` pageTitle)
                tagsContext = mconcat [ constField "title" pageTitle
                                      , field cloudName renderedCloud
                                      , defaultContext
                                      ]
            defaultTemp <- defaultTemplate
            specificTemp <- specificTemplate
            makeItem "" >>= applyTemplate specificTemp tagsContext
                        >>= applyTemplate defaultTemp tagsContext
                        >>= relativizeUrls

-- Формируем страницу с облаком тематических тегов.
createPageWithAllTags :: TagsReader
createPageWithAllTags = do
    tagsAndAuthors <- ask
    lift $ createPageWithTagsCloud (head tagsAndAuthors)
                                   "tags.html"
                                   110
                                   220
                                   "Темы"
                                   "tagsCloud"
                                   tagsTemplate
    return ()

-- Формируем страницу с облаком категорий.
createPageWithAllCategories :: TagsReader
createPageWithAllCategories = do
    tagsAndAuthors <- ask
    lift $ createPageWithTagsCloud (tagsAndAuthors !! 1)
                                   "categories.html"
                                   110
                                   220
                                   "Разделы"
                                   "categoriesCloud"
                                   categoriesTemplate
    return ()

-- Формируем страницу с облаком авторов публикаций.
createPageWithAllAuthors :: TagsReader
createPageWithAllAuthors = do
    tagsAndAuthors <- ask
    lift $ createPageWithTagsCloud (tagsAndAuthors !! 2)
                                   "authors.html"
                                   110
                                   220
                                   "Наши авторы"
                                   "authorsCloud"
                                   authorsTemplate
    return ()

convertSpecificTagsToLinks :: TagsAndAuthors
                           -> Tags
                           -> String
                           -> Rules ()
convertSpecificTagsToLinks tagsAndAuthors specificTags aTitle =
    tagsRules specificTags $ \tag ptrn -> do
        let nameOfTag = if "разделе" `isInfixOf` aTitle then getRussianNameOfCategory tag else tag
            title = renderHtml $ H.preEscapedToHtml $ aTitle ++ " " ++ nameOfTag
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll ptrn
            let taggedPostsContext = mconcat [ listField "posts" (postContext tagsAndAuthors) (return posts)
                                             , constField "title" title
                                             , defaultContext
                                             ]
            postsTemp <- postsTemplate
            defaultTemp <- defaultTemplate
            makeItem "" >>= applyTemplate postsTemp taggedPostsContext
                        >>= applyTemplate defaultTemp taggedPostsContext
                        >>= relativizeUrls

-- Делаем тематические теги ссылками, что позволит отфильтровать статьи по тегам.
convertTagsToLinks :: TagsReader
convertTagsToLinks = do
    tagsAndAuthors <- ask
    lift $ convertSpecificTagsToLinks tagsAndAuthors
                                      (head tagsAndAuthors)
                                      "Всё по теме"
    return ()

-- Делаем названия категорий ссылками, что позволит отфильтровать статьи по категориям.
convertCategoriesToLinks :: TagsReader
convertCategoriesToLinks = do
    tagsAndAuthors <- ask
    lift $ convertSpecificTagsToLinks tagsAndAuthors
                                      (tagsAndAuthors !! 1)
                                      "Всё в разделе"
    return ()

-- Делаем имена авторов ссылками, что позволит отфильтровать статьи по авторам.
convertAuthorsToLinks :: TagsReader
convertAuthorsToLinks = do
    tagsAndAuthors <- ask
    lift $ convertSpecificTagsToLinks tagsAndAuthors
                                      (tagsAndAuthors !! 2)
                                      "Все труды автора"
    return ()
