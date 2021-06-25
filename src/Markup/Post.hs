{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Markup.Post
    ( postTemplate
    , disqusCount
    ) where

import           Prelude hiding (div)

import           Data.String.QQ (s)
import           Data.Text (Text)
import           Hakyll.Web.Template
import           Text.Blaze.Html.Renderer.Pretty (renderHtml)
import           Text.Blaze.Html5
import qualified Text.Blaze.Html5.Attributes as A
import           Hakyll                        (makeItem, Compiler)
import           Control.Monad                 ( (<=<) )


postTemplate :: Compiler Template
postTemplate = compileTemplateItem <=< makeItem  . renderHtml $ raw

raw :: Html
raw = do
    h1 "$title$"

    div ! A.class_ "row" $ do
        div ! A.class_ "col-xs-9 col-sm-8 col-md-8 col-lg-8" $
            div ! A.class_ "post-info" $ preEscapedToHtml postInfo

        div ! A.class_ "col-xs-3 col-sm-4 col-md-4 col-lg-4" $
            preEscapedToHtml linkToOriginal

    talkHeader
    div "$body$"

    div ! A.class_ "social-buttons-separator" $ ""
    div ! A.id "socialButtons" $ preEscapedToHtml socialButtons
    div ! A.class_ "social-buttons-separator" $ ""
    div $ preEscapedToHtml disqusThread

postInfo :: String
postInfo = [s|
<strong>let</strong> author&nbsp;&nbsp;&nbsp;= "$postAuthor$"<br/>
&nbsp;&nbsp;&nbsp;&nbsp;date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;= fromGregorian $haskellDate$<br/>
&nbsp;&nbsp;&nbsp;&nbsp;category = "$postCategory$"<br/>
&nbsp;&nbsp;&nbsp;&nbsp;tags&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;= [$postTags$]
|]

linkToOriginal :: String
linkToOriginal = [s|
$if(hrefToOriginal)$
    <div class="href-to-original">
        <a href="$hrefToOriginal$" target="_blank">Оригинал <span class="fa fa-external-link"></span></a>
    </div>
$endif$
|]

socialButtons :: String
socialButtons = [s|
<a href="https://twitter.com/share" class="twitter-share-button" data-lang="ru" data-size="large">Твитнуть</a> <script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');</script>
|]

disqusThread :: String
disqusThread = [s|<div id="disqus_thread"></div>|] ++ disqusBlock "embed"

disqusCount :: String
disqusCount = disqusBlock "count"

disqusBlock :: String -> String
disqusBlock scriptName = [s|
    <script type="text/javascript">
        /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
        var disqus_shortname = 'ruhaskell'; // required: replace example with your forum shortname

        /* * * DON'T EDIT BELOW THIS LINE * * */
        (function() {
            var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
            dsq.src = '//' + disqus_shortname + '.disqus.com/|] ++ scriptName ++ [s|.js';
            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
        })();
    </script>
    |]

talkHeader :: Html
talkHeader = do
    "$if(talk.event)$" :: Html
    div $
        a ! A.href "/categories/talks.html" $ do
            preEscapedToHtml ("&uarr;&nbsp;" :: Text)
            "все доклады"
    div $
        a ! A.href "$talk.event$" $ do
            preEscapedToHtml ("&uarr;&nbsp;" :: Text)
            "все доклады с этого события"
    "$endif$" :: Html

    "$if(talk.video)$" :: Html
    div ! A.style "white-space: nowrap" $ "$talk.video$"
    "$endif$" :: Html
