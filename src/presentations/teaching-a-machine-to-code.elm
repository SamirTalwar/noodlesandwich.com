module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (alt, class, href, src, style)
import NoodleSandwich.Slides as Slides


main : Program Never Slides.Model Slides.Message
main =
    Slides.program
        { slides = slides
        , extraHtml = []
        }


slides : Slides.Slides
slides =
    [ [ h1 [] [ text "Teaching a Machine to Code" ]
      , h2 []
            [ text "@SamirTalwar"
            , br [] []
            , text "prodo"
            , span [ style [ ( "color", "#00e3a0" ) ] ] [ text ".ai" ]
            ]
      , h3 []
            [ text "Joy of Coding"
            , br [] []
            , text "2018-06-08T12:00:00+0200"
            ]
      ]
    , [ h1 [] [ text "People are awful at programming." ] ]
    , [ pre []
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "> leftPad(37, 5, '0')"
                        , "'00037'"
                        ]
                ]
            ]
      ]
    , [ pre [ style [ ( "font-size", "0.6em" ) ] ]
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "module.exports = leftPad;"
                        , ""
                        , "var cache = [ /* ... */ ];"
                        , ""
                        , "function leftPad (str, len, ch) {"
                        , "  str = str + '';"
                        , "  len = len - str.length;"
                        , "  if (len <= 0) return str;"
                        , "  if (!ch && ch !== 0) ch = ' ';"
                        , "  ch = ch + '';"
                        , "  if (ch === ' ' && len < 10) return cache[len] + str;"
                        , "  var pad = '';"
                        , "  while (true) {"
                        , "    if (len & 1) pad += ch;"
                        , "    len >>= 1;"
                        , "    if (len) ch += ch;"
                        , "    else break;"
                        , "  }"
                        , "  return pad + str;"
                        , "}"
                        ]
                ]
            ]
      ]
    , [ p []
            [ a
                [ href "https://github.com/stevemao/left-pad/commit/6b25e7775731eb0f5bb5d243a84f609707da6bd7" ]
                [ text "commit 6b25e77" ]
            ]
      , pre []
            [ code [ class "language-diff" ]
                [ text <|
                    lines
                        [ "@@ -6,6 +6,8 @@ function leftpad (str, len, ch) {"
                        , "   ch || (ch = ' ');"
                        , "   len = len - str.length;"
                        , ""
                        , "+  str = String(str);"
                        , "+"
                        , "   while (++i < len) {"
                        , "     str = ch + str;"
                        , "   }"
                        ]
                ]
            ]
      ]
    , [ div [ style [ ( "font-size", "0.5em" ) ] ]
            [ p []
                [ a
                    [ href "https://github.com/stevemao/left-pad/commit/6b25e7775731eb0f5bb5d243a84f609707da6bd7" ]
                    [ text "commit 6b25e77" ]
                ]
            , pre []
                [ code [ class "language-diff" ]
                    [ text <|
                        lines
                            [ "@@ -6,6 +6,8 @@ function leftpad (str, len, ch) {"
                            , "   ch || (ch = ' ');"
                            , "   len = len - str.length;"
                            , ""
                            , "+  str = String(str);"
                            , "+"
                            , "   while (++i < len) {"
                            , "     str = ch + str;"
                            , "   }"
                            ]
                    ]
                ]
            , p []
                [ a
                    [ href "https://github.com/stevemao/left-pad/commit/7aa20d4289b7c706787adfcff7056f7bc0349e62" ]
                    [ text "commit 7aa20d4" ]
                ]
            , pre []
                [ code [ class "language-diff" ]
                    [ text <|
                        lines
                            [ "@@ -1,12 +1,13 @@"
                            , " module.exports = leftpad;"
                            , ""
                            , " function leftpad (str, len, ch) {"
                            , "+  str = String(str);"
                            , "+"
                            , "   var i = -1;"
                            , ""
                            , "   ch || (ch = ' ');"
                            , "   len = len - str.length;"
                            , ""
                            , "-  str = String(str);"
                            , ""
                            , "   while (++i < len) {"
                            , "     str = ch + str;"
                            ]
                    ]
                ]
            ]
      ]
    , [ p [] [ text "Dynamic languages have power." ]
      , hidden <| p [] [ text "And with power comes responsibility." ]
      ]
    , [ p [] [ text "Dynamic languages have power." ]
      , p [] [ text "And with power comes responsibility." ]
      ]
    , [ p [] [ text "But I don't want responsibility for mechanical checks." ]
      ]
    , [ p [] [ text "I am not a machine." ]
      ]
    , [ div []
            [ p [ style [ ( "height", "50%" ), ( "opacity", "0.25" ), ( "text-align", "center" ) ] ]
                [ img [ src "/assets/presentations/teaching-a-machine-to-code/kitchener.png" ] []
                ]
            , h3 [] [ text "Ask not what you can do for your machine" ]
            , h3 [] [ text "But what your machine can do for you!" ]
            ]
      ]
    , [ h1 [] [ text "Just Fix It, Please" ] ]
    , [ p [] [ text "Autofix" ]
      , toy "autofix"
      ]
    , [ h1 [] [ text "Huh, That Looks Funny…" ] ]
    , [ p [] [ text "Anomaly Detection" ]
      , toy "token-prediction"
      ]
    , [ blockquote []
            [ p [] [ text "Real software, the kind working programmers produce by the kLOC to solve real-world problems, tends to be \"natural\", like speech or natural language; it tends to be highly repetitive and predictable." ]
            , cite []
                [ text "— "
                , a [ href "https://arxiv.org/abs/1506.01159\n" ]
                    [ text "On The \"Naturalness\" of Buggy Code" ]
                , text ", 2015"
                ]
            ]
      ]
    , [ h1 [] [ text "What even is this?" ] ]
    , [ pre []
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "function add(x, y) {"
                        , "  return x + y;"
                        , "}"
                        ]
                ]
            ]
      ]
    , [ pre [ style [ ( "font-size", "0.75em" ) ] ]
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "> 1 + 2"
                        , "3"
                        , "> '1' + '2'"
                        , "'12'"
                        , "> 3 + '4'"
                        , "'34'"
                        , "> null + undefined"
                        , "NaN"
                        , "> null + 'x'"
                        , "'nullx'"
                        , "> {} + []"
                        , "0"
                        ]
                ]
            ]
      ]
    , [ p [] [ text "Type Inference" ]
      , toy "type-inference"
      ]
    , [ h1 [] [ text "I've Seen That Before…" ] ]
    , [ p [] [ text "Image-Based Clone Detection" ]
      , toy "clone-detection"
      ]
    , [ h1 [] [ text "Be Dissatisfied" ] ]
    , [ h1 [] [ text "What's Next?" ]
      , div []
            [ p []
                [ text "Cyclomatic complexity?"
                , br [] []
                , hidden <| text "What is \"good\" code?"
                ]
            , p []
                [ text "PMD?"
                , br [] []
                , hidden <| text "How do we measure \"good\" design?"
                ]
            , p []
                [ text "Test coverage?"
                , br [] []
                , hidden <| text "How do we know that this will work?"
                ]
            ]
      ]
    , [ h1 [] [ text "What's Next?" ]
      , div []
            [ p []
                [ del [] [ text "Cyclomatic complexity?" ]
                , br [] []
                , ins [] [ text "What is \"good\" code?" ]
                ]
            , p []
                [ del [] [ text "PMD?" ]
                , br [] []
                , ins [] [ text "How do we measure \"good\" design?" ]
                ]
            , p []
                [ del [] [ text "Test coverage?" ]
                , br [] []
                , ins [] [ text "How do we know that this will work?" ]
                ]
            ]
      ]
    , [ p [] [ text "We're used to tools that slap us on the wrist." ]
      , p [] [ text "I want my computer to pair with me." ]
      ]
    , [ h1 [] [ text "Why should you care?" ] ]
    , [ h1 [] [ text "You're a creative." ] ]
    , [ h1 [] [ text "Be a human." ]
      , p [] [ text "Teach your machine to do the mechanical parts." ]
      ]
    , [ p [] [ text "And when you're ready to change the world, ", a [ href "https://prodo.ai/jobs" ] [ text "come join us" ], text "." ] ]
    , [ p [] [ a [ href "https://noodlesandwich.com/" ] [ text "noodlesandwich.com" ] ]
      , p [] [ a [ href "https://toybox.prodo.ai/" ] [ text "toybox.prodo.ai" ] ]
      , p [] [ a [ href "https://prodo.ai/jobs" ] [ text "prodo.ai/jobs" ] ]
      ]
    ]


hidden : Html a -> Html a
hidden element =
    div [ style [ ( "visibility", "hidden" ) ] ] [ element ]


lines : List String -> String
lines =
    String.join "\n"


toy : String -> Html a
toy name =
    iframe
        [ src ("https://toybox.prodo.ai/widget/" ++ name)
        , style [ ( "width", "100%" ), ( "height", "600px" ), ( "border", "0" ) ]
        ]
        []
