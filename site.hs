{-# LANGUAGE OverloadedStrings #-}

--------------------------------------------------------------------------------
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Pandoc (HTMLMathMethod (MathJax), writerHTMLMathMethod)

--------------------------------------------------------------------------------
main :: IO ()
main =
  hakyllWith (defaultConfiguration {deployCommand = "./deploy.sh"}) $ do
    match "images/*" $ do
      route idRoute
      compile copyFileCompiler
    match "css/*.css" $ do
      route idRoute
      compile compressCssCompiler
    match (fromList ["about.rst", "contact.markdown"]) $ do
      route $ setExtension "html"
      let readerOptions = defaultHakyllReaderOptions
      let writerOptions =
            defaultHakyllWriterOptions {writerHTMLMathMethod = MathJax ""}
      compile $
        pandocCompilerWith readerOptions writerOptions >>=
        loadAndApplyTemplate "templates/default.html" defaultContext >>=
        relativizeUrls
    match "posts/*" $ do
      route $ setExtension "html"
      let readerOptions = defaultHakyllReaderOptions
      let writerOptions =
            defaultHakyllWriterOptions {writerHTMLMathMethod = MathJax ""}
      compile $
        pandocCompilerWith readerOptions writerOptions >>=
        saveSnapshot "content" >>=
        loadAndApplyTemplate "templates/post.html" postCtx >>=
        loadAndApplyTemplate "templates/default.html" postCtx >>=
        relativizeUrls
    create ["blog.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots "posts/*" "content"
        let archiveCtx =
              listField "posts" postCtx (return posts) `mappend`
              constField "title" "Archives" `mappend`
              defaultContext
        makeItem "" >>= loadAndApplyTemplate "templates/blog.html" archiveCtx >>=
          loadAndApplyTemplate "templates/default.html" archiveCtx >>=
          relativizeUrls
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots "posts/*" "content"
        let indexCtx =
              listField "posts" postCtx (return posts) `mappend` defaultContext
        getResourceBody >>= applyAsTemplate indexCtx >>=
          loadAndApplyTemplate "templates/default.html" indexCtx >>=
          relativizeUrls
    match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx = dateField "date" "%B %e, %Y" <> bodyField "summary" <> defaultContext
