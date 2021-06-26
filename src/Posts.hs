{-
    Модуль, отвечающий за преобразование статей и в формирование корректных путей к ним.
    https://github.com/ruHaskell/ruhaskell
    Все права принадлежат русскоязычному сообществу Haskell-разработчиков, 2015-2016 г.
-}

{-# LANGUAGE OverloadedStrings #-}

module Posts (
    createPosts
) where

import           Control.Monad.Reader (ReaderT (..))
import           Data.List (intercalate)
import           Data.List.Split (splitOn)
import           GHC.Stack (HasCallStack)
import           Hakyll (Routes, applyTemplate, compile, composeRoutes,
                         customRoute, defaultHakyllReaderOptions,
                         defaultHakyllWriterOptions, match, pandocCompilerWith,
                         relativizeUrls, route, setExtension, toFilePath)
import           System.FilePath (dropExtension, joinPath)
import           Text.Pandoc.Options (HTMLMathMethod (..), WriterOptions (..))

import           Context (postContext)
import           Markup.Default (defaultTemplate)
import           Markup.Post (postTemplate)
import           Misc (TagsReader)

-- Дата публикации будет отражена в URL в виде подкаталогов.
directorizeDate :: Routes
directorizeDate = customRoute (directorize . toFilePath)
  where
    directorize path = dropExtension $ joinPath [y, m, d, intercalate "-" title]
      where
        (y, m, d, title) = case splitOn "-" path of
            y' : m' : d' : t -> (y', m', d', t)
            _ -> error "file name must be in format `y-m-d-title`"

createPosts :: HasCallStack => TagsReader
createPosts = ReaderT $ \tagsAndAuthors ->
    match "posts/**" $ do
        route $ directorizeDate `composeRoutes` setExtension "html"
        -- Для превращения Markdown в HTML используем pandocCompiler
        compile $ do
            postTemp <- postTemplate
            defaultTemp <- defaultTemplate
            pandocCompilerWith
                defaultHakyllReaderOptions
                defaultHakyllWriterOptions{writerHTMLMathMethod = MathJax ""}
              >>= applyTemplate postTemp    (postContext tagsAndAuthors)
              >>= applyTemplate defaultTemp (postContext tagsAndAuthors)
              >>= relativizeUrls
