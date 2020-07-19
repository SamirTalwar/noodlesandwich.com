module Presentations.PlzRespectUrData exposing (main)

import Html exposing (..)
import Html.Attributes exposing (alt, class, href, src, style)
import NoodleSandwich.Slides as Slides


main : Program () Slides.Model Slides.Message
main =
    Slides.program
        { title = "Plz, Respect Ur Data"
        , slides = slides
        , extraHtml = []
        }


slides : Slides.Slides
slides =
    [ [ h1 [] [ text "Plz, Respect Ur Data" ]
      , h2 []
            [ text "@SamirTalwar"
            , br [] []
            , text "prodo"
            , span [ style "color" "#00e3a0" ] [ text ".ai" ]
            ]
      , h3 []
            [ text "RAPIDS"
            , br [] []
            , text "2018-11-22T19:25:00Z"
            ]
      ]
    , [ h1 [] [ text "We think software is important." ] ]
    , [ p [] [ text "£28 per month, over 12 months" ]
      , pre [] [ text "28 * 12" ]
      , pre [] [ text <| lines [ "$ bc <<< '28 * 12'", "336" ] ]
      ]
    , [ p [] [ text "It's not the software that's important." ]
      , p [] [ text "It's the result." ]
      ]
    , [ p [] [ em [] [ text "Chorus of data scientists:" ] ]
      , p [] [ text "YES, WE KNOW." ]
      ]
    , [ p [] [ img [ src "https://assets.noodlesandwich.com/talks/plz-respect-ur-data/jupyter-notebook-lorenz.gif" ] [] ]
      , p []
            [ text "Source: "
            , cite []
                [ a
                    [ href "https://mybinder.org/v2/gh/jupyterlab/jupyterlab-demo/master?urlpath=lab%2Ftree%2Fdemo%2FLorenz.ipynb" ]
                    [ text "Try JupyterLab" ]
                ]
            ]
      ]
    , [ h1 []
            [ text "Introducing "
            , a [ href "https://github.com/prodo-ai/plz" ] [ text "Plz" ]
            ]
      , p [] [ a [ href "https://github.com/prodo-ai/plz" ] [ text "https://github.com/prodo-ai/plz" ] ]
      ]
    , [ p [] [ text "At Prodo.AI, we were faced with two problems:" ]
      , ol []
            [ li [] [ text "How do we ensure we don't lose valuable models?" ]
            , li [] [ text "How do we train them as cheaply as possible?" ]
            ]
      ]
    , [ h1 [] [ text "Demo Time" ] ]
    , [ p []
            [ text "Plz operates on a set of principles:" ]
      , ol
            []
            [ li [] [ text "The faster you can iterate, the better your results." ]
            , li [] [ text "You don't know the value of your data at the time of creation." ]
            , li [] [ text "Data that isn't reproducible is worthless." ]
            , li [] [ text "Code is a means to an end." ]
            , li [] [ text "Hardware is expensive." ]
            ]
      ]
    , [ p [] [ text "None of your contemporaries or customers care about your software. It's a means to an end." ] ]
    , [ p [] [ text "You probably already know this." ]
      , p [] [ text "Your tooling is behind." ]
      ]
    , [ p [] [ text "The Plz Roadmap:" ]
      , ul []
            [ li [] [ text "parallel runs with hyper-parameter searching" ]
            , li [] [ text "cloud storage support" ]
            , li [] [ text "cloud-agnostic redesign" ]
            , li [] [ text "a friendly UI" ]
            ]
      ]
    , [ p [] [ text "Come and help us figure out what to do next." ]
      , p [] [ a [ href "https://github.com/prodo-ai/plz/issues" ] [ text "https://github.com/prodo-ai/plz/issues" ] ]
      , p [] [ a [ href "https://noodlesandwich.com/talks/plz-respect-ur-data" ] [ text "https://noodlesandwich.com/talks/plz-respect-ur-data" ] ]
      ]
    ]


lines : List String -> String
lines =
    String.join "\n"
