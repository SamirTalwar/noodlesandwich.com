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
    ]
