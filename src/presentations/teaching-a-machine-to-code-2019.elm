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
            [ text "Newcrafts Paris 2019"
            , br [] []
            , text "2019-05-16T10:30:00+0200"
            ]
      ]
    , [ h1 [] [ text "What does it mean to be human?" ] ]
    , [ p [] [ text "Foucalt said:" ]
      , blockquote [] [ text "\"Je ne pense pas qu'il soit nécessaire de savoir exactement qui je suis. Ce qui fait l'intérêt principal de la vie et du travail est qu'ils vous permettent de devenir quelqu'un de différent de ce que vous étiez au départ.\"" ]
      , hidden <| blockquote [] [ text "\"I don't feel that it is necessary to know exactly what I am. The main interest in life and work is to become someone else that you were not in the beginning.\"" ]
      ]
    , [ p [] [ text "Foucalt said:" ]
      , blockquote [] [ text "\"Je ne pense pas qu'il soit nécessaire de savoir exactement qui je suis. Ce qui fait l'intérêt principal de la vie et du travail est qu'ils vous permettent de devenir quelqu'un de différent de ce que vous étiez au départ.\"" ]
      , blockquote [] [ text "\"I don't feel that it is necessary to know exactly what I am. The main interest in life and work is to become someone else that you were not in the beginning.\"" ]
      ]
    , [ p [] [ text "Descartes put it more simply:" ]
      , blockquote [] [ text "\"Cogito ergo sum.\"" ]
      , hidden <| blockquote [] [ text "\"I think, therefore I am.\"" ]
      ]
    , [ p [] [ text "Descartes put it more simply:" ]
      , blockquote [] [ text "\"Cogito ergo sum.\"" ]
      , blockquote [] [ text "\"I think, therefore I am.\"" ]
      ]
    , [ p [] [ text "And for the core of it all, we need look no further than Sartre." ]
      , blockquote [] [ text "\"Nous sommes nos choix.\"" ]
      , hidden <| blockquote [] [ text "\"We are our choices.\"" ]
      ]
    , [ p [] [ text "And for the core of it all, we need look no further than Sartre." ]
      , blockquote [] [ text "\"Nous sommes nos choix.\"" ]
      , blockquote [] [ text "\"We are our choices.\"" ]
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
    , [ p []
            [ a
                [ href "https://github.com/stevemao/left-pad/commit/7aa20d4289b7c706787adfcff7056f7bc0349e62" ]
                [ text "commit 7aa20d4" ]
            ]
      , pre [ style [ ( "font-size", "0.8em" ) ] ]
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
                [ img [ src "https://assets.noodlesandwich.com/talks/teaching-a-machine-to-code/kitchener.png" ] []
                ]
            , h3 [] [ text "Ask not what you can do for your machine" ]
            , h3 [] [ text "But what your machine can do for you!" ]
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
    , [ h1 [] [ text "Just Fix It, Please" ] ]
    , [ p [] [ text "Autofix" ]
      , toy "autofix"
      ]
    , [ h1 [] [ text "Be Dissatisfied" ] ]
    , [ h1 [] [ text "Symbiosis" ] ]
    , [ p [] [ text "Agility" ]
      , embedded "https://alfie.prodo.ai/tame-stocking-filler/3"
      ]
    , [ p [] [ text "Machines don't have to be smart to help you." ]
      , p [] [ text "They're good at doing one thing very fast." ]
      , p [] [ text "Given the data, a human can make smart decisions." ]
      ]
    , [ h2 [] [ text "Principles of the Agile Manifesto" ]
      , ul []
            [ li [] [ text "Our highest priority is to satisfy the customer through early and continuous delivery of valuable software." ]
            , li [] [ text "Welcome changing requirements, even late in development. […]" ]
            , li [] [ text "Deliver working software frequently […]" ]
            , li [] [ text "[…] work together daily […]" ]
            , li [] [ text "The most efficient and effective method of conveying information […] is face-to-face conversation." ]
            , li [] [ text "Continuous attention […] enhances agility." ]
            , li [] [ text "At regular intervals, the team reflects […]" ]
            ]
      ]
    , [ h1 [] [ text "Feedback is all that matters." ] ]
    , [ h1 [] [ text "And on the front-end…" ]
      ]
    , [ p [] [ text "Introducing Codename: Snoopy." ] ]
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
                [ text "Acceptance tests?"
                , br [] []
                , hidden <| text "How can we be sure this is what we need?"
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
                [ text "Acceptance tests?"
                , br [] []
                , text "How can we be sure this is what we need?"
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
    , [ p [] [ a [ href "https://twitter.com/SamirTalwar" ] [ text "@SamirTalwar" ] ]
      , p [] [ a [ href "https://noodlesandwich.com/" ] [ text "noodlesandwich.com" ] ]
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
    embedded <| "https://toybox.prodo.ai/widget/" ++ name


embedded : String -> Html a
embedded url =
    iframe
        [ src url
        , style [ ( "width", "100%" ), ( "height", "600px" ), ( "border", "0" ) ]
        ]
        []
