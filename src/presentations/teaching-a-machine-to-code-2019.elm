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
    ]
        ++ citation "Michel Foucault"
            [ "\"Je ne pense pas qu'il soit nécessaire de savoir exactement qui je suis. Ce qui fait l'intérêt principal de la vie et du travail est qu'ils vous permettent de devenir quelqu'un de différent de ce que vous étiez au départ.\""
            , "\"I don't feel that it is necessary to know exactly what I am. The main interest in life and work is to become someone else that you were not in the beginning.\""
            ]
        ++ citation "René Descartes"
            [ "\"Cogito ergo sum.\""
            , "\"I think, therefore I am.\""
            ]
        ++ citation "Jean-Paul Sartre"
            [ "\"Nous sommes nos choix.\""
            , "\"We are our choices.\""
            ]
        ++ [ [ table []
                [ thead []
                    [ tr []
                        [ td [] [ strong [] [ text "Humans" ] ]
                        , td [] [ strong [] [ text "Machines" ] ]
                        ]
                    ]
                , tbody
                    []
                    [ tr []
                        [ td [] [ text "make guesses" ]
                        , td [] [ text "are logical" ]
                        ]
                    , tr []
                        [ td [] [ text "are forgiving" ]
                        , td [] [ text "are precise" ]
                        ]
                    , tr []
                        [ td [] [ text "assume from context" ]
                        , td [] [ text "are unassuming" ]
                        ]
                    , tr []
                        [ td [] [ text "are visual" ]
                        , td [] [ text "process bits" ]
                        ]
                    ]
                ]
             ]
           , [ h1 [] [ text "Humans are awful at programming." ] ]
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
           , [ p [] [ text "What are the types of the parameters to this function?" ]
             , pre []
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
           , [ p [] [ text "And how about this one?" ]
             , pre []
                [ code [ class "language-javascript" ]
                    [ text <|
                        lines
                            [ "function concatenate(str1, str2) {"
                            , "  return str1 + str2;"
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
             , embedded "https://toybox.prodo.ai/typewriter/Types/?c=function+add%28x%2C+y%29+%7B%0A++return+x+%2B+y%3B%0A%7D%0A"
             ]
           , [ h1 [] [ text "Just Fix It, Please" ] ]
           , [ p [] [ text "Do you how know to read this?" ] ]
           , [ pre []
                [ code [ class "language-javascript" ]
                    [ text <|
                        lines
                            [ "const numbers = [1, 2, 3;"
                            , "console.log(numbers);"
                            ]
                    ]
                ]
             ]
           , [ p [] [ text "Autofix" ]
             , embedded "https://toybox.prodo.ai/autofix/DiffText/?c=const+numbers+%3D+%5B1%2C+2%2C+3%3B%0Anumbers.forEach%28console.log%29%3B%0A"
             ]
           , [ h1 [] [ text "Be Dissatisfied" ] ]
           , [ h1 [] [ text "Symbiosis" ] ]
           , [ p [] [ text "Agility" ]
             , embedded "https://alfie.prodo.ai/tame-stocking-filler/4"
             ]
           , [ p [] [ text "Machines don't have to be smart to help you." ]
             , p [] [ text "They're good at doing one thing very fast." ]
             , p [] [ text "Given the data, a human can make smart decisions." ]
             ]
           , [ h2 [] [ text "Principles of the Agile Manifesto" ]
             , ul []
                [ li [] [ text "early and continuous delivery" ]
                , li [] [ text "changing requirements" ]
                , li [] [ text "deliver […] frequently" ]
                , li [] [ text "work together daily" ]
                , li [] [ text "is face-to-face conversation" ]
                , li [] [ text "continuous attention […] enhances agility" ]
                , li [] [ text "At regular intervals, the team reflects" ]
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
                    [ del [] [ text "Acceptance tests?" ]
                    , br [] []
                    , ins [] [ text "How can we be sure this is what we need?" ]
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
           ]
        ++ fromMaybe
            (last
                (citation "Jean-Paul Sartre"
                    [ "\"Nous sommes nos choix.\""
                    , "\"We are our choices.\""
                    ]
                )
            )
        ++ [ [ p [] [ a [ href "https://twitter.com/SamirTalwar" ] [ text "@SamirTalwar" ] ]
             , p [] [ a [ href "https://noodlesandwich.com/" ] [ text "noodlesandwich.com" ] ]
             , p [] [ a [ href "https://toybox.prodo.ai/" ] [ text "toybox.prodo.ai" ] ]
             , p [] [ img [ src "https://assets.noodlesandwich.com/prodo.ai/logo/light.svg", alt "prodo.ai" ] [] ]
             ]
           ]


citation : String -> List String -> List (List (Html a))
citation author quotes =
    let
        ns =
            List.range 1 (List.length quotes)
    in
        ns
            |> List.map
                (\slideIndex ->
                    List.map2
                        (\quote quoteIndex ->
                            (if quoteIndex <= slideIndex then
                                identity
                             else
                                hidden
                            )
                            <|
                                blockquote [] [ text quote ]
                        )
                        quotes
                        ns
                        ++ [ p [] [ cite [] [ text ("— " ++ author) ] ]
                           ]
                )


hidden : Html a -> Html a
hidden element =
    div [ style [ ( "visibility", "hidden" ) ] ] [ element ]


embedded : String -> Html a
embedded url =
    iframe
        [ src url
        , style [ ( "width", "100%" ), ( "height", "600px" ), ( "border", "0" ) ]
        ]
        []


lines : List String -> String
lines =
    String.join "\n"


last : List a -> Maybe a
last list =
    List.head <| List.drop (List.length list - 1) list


fromMaybe : Maybe a -> List a
fromMaybe maybe =
    case maybe of
        Nothing ->
            []

        Just x ->
            [ x ]
