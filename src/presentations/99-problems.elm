module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (alt, class, href, src, style)
import NoodleSandwich.Slides as Slides
import String


main : Program Never Slides.Model Slides.Message
main =
    Slides.program
        { slides = slides
        , extraHtml = [ node "script" [ src "https://assets.codepen.io/assets/embed/ei.js" ] [] ]
        }


slides : Slides.Slides
slides =
    [ [ h1 [] [ text "I've got 99 problems and asynchronous programming is 127 of them" ]
      , h2 []
            [ text "@SamirTalwar"
            , br [] []
            , text "prodo"
            , span [ style [ ( "color", "#00e3a0" ) ] ] [ text ".ai" ]
            ]
      , h3 []
            [ text "Codemotion Berlin"
            , br [] []
            , text "2016-10-24T16:30:00+0200"
            ]
      ]
    , [ h1 [] [ text "What this talk is" ]
      , ul []
            [ li [] [ text "JavaScript-focused" ]
            , li [] [ text "Fairly simple" ]
            , li [] [ text "Client and server" ]
            , li [] [ text "Reactive code" ]
            , li [] [ text "… but not about React" ]
            ]
      ]
    , [ h1 [] [ text "We'll start from the beginning." ]
      ]
    , [ h1 [] [ text "Concurrency is hard,", br [] [], text "am I right?" ]
      , p [] [ text "Or, at least, it was, before JavaScript came along." ]
      , p [] [ text "It solved this problem by not allowing concurrency." ]
      ]
    , [ h1 [] [ text "Wait. That’s not right." ]
      ]
    , [ p [] [ text "JavaScript runtimes don’t allow ", em [] [ text "parallelism" ], text "." ]
      ]
    , [ h1 [] [ text "Parallelism" ]
      , div [ class "prose" ]
            [ p []
                [ text "If two things run in \"parallel\", they are literally happening at the exact same time."
                ]
            , p []
                [ text "Parallelism is about the real-world characteristics of your computer."
                ]
            ]
      ]
    , [ h1 [] [ text "Concurrency" ]
      , div [ class "prose" ]
            [ p []
                [ text "\"Concurrent\" software is software that is written so that work may be interleaved without causing any problems."
                ]
            , p []
                [ text "You need concurrency before you parallelize."
                ]
            ]
      ]
    , [ p []
            [ text "Software is concurrent."
            ]
      , p []
            [ text "Hardware is parallel."
            ]
      ]
    , [ h1 [] [ text "The event loop" ]
      , div [ class "prose" ]
            [ p []
                [ text "Modern JavaScript has more in common with video game development than it does traditional application development."
                ]
            ]
      ]
    , [ h1 [] [ text "The event loop" ]
      , pre []
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "while (let event = eventQueue.next()) {"
                        , "  process(event)"
                        , "}"
                        ]
                ]
            ]
      ]
    , [ h1 [] [ text "Synchronous programming" ]
      , pre []
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "var request = new XMLHttpRequest()"
                        , "request.open('GET', 'something.json', false)"
                        , ""
                        , "request.send(null)"
                        , "// execution pauses here until we get a response"
                        , "alert('Response:\\n' + this.responseText)"
                        ]
                ]
            ]
      ]
    , [ h1 [] [ text "Asynchronous programming" ]
      , pre []
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "var request = new XMLHttpRequest()"
                        , "request.onreadystatechange = function () {"
                        , "  if (this.readyState === 4) {"
                        , "    alert('Response:\\n' + this.responseText)"
                        , "  }"
                        , "}"
                        , "request.open('GET', 'something.json', true)"
                        , "request.send(null)"
                        ]
                ]
            ]
      ]
    , [ h1 [] [ text "On to the meat." ]
      ]
    , [ h1 [] [ text "Thanks, node.js." ]
      , pre [ style [ ( "font-size", "0.6em" ) ] ]
            [ code [ class "language-javascript" ]
                [ text <|
                    lines
                        [ "fs.readdir(source, function (err, files) {"
                        , "  if (err) {"
                        , "    console.log('Error finding files: ' + err)"
                        , "  } else {"
                        , "    files.forEach(function (filename, fileIndex) {"
                        , "      console.log(filename)"
                        , "      gm(source + filename).size(function (err, values) {"
                        , "        if (err) {"
                        , "          console.log('Error identifying file size: ' + err)"
                        , "        } else {"
                        , "          console.log(filename + ' : ' + values)"
                        , "          aspect = (values.width / values.height)"
                        , "          widths.forEach(function (width, widthIndex) {"
                        , "            height = Math.round(width / aspect)"
                        , "            console.log('resizing ' + filename + 'to ' + height + 'x' + height)"
                        , "            this.resize(width, height).write(dest + 'w' + width + '_' + filename, function(err) {"
                        , "              if (err) console.log('Error writing file: ' + err)"
                        , "            })"
                        , "          }.bind(this))"
                        , "        }"
                        , "      })"
                        , "    })"
                        , "  }"
                        , "})"
                        ]
                ]
            ]
      ]
    , [ h1 [] [ text "Introducing asynchronous JavaScript" ] ]
    , [ codepen 1 1 "99 bottles" "VKqJgk" ]
    , [ codepen 1 2 "99 bottles, take 2" "YGdorP" ]
    , [ codepen 1 3 "99 bottles, take 3" "kkzKmp" ]
    , [ codepen 1 4 "99 bottles, take 4" "BLvXok" ]
    , [ codepen 1 5 "99 bottles, take 5" "PGVpgQ" ]
    , [ h2 [] [ text "… and back we go again" ] ]
    , [ codepen 1 6 "99 bottles, take 6" "rroXrq" ]
    , [ codepen 1 7 "99 bottles, take 7" "ozmBLa" ]
    , [ h1 [] [ text "From callbacks to promises" ] ]
    , [ codepen 2 1 "Where in the world am I?" "YGdmJk" ]
    , [ codepen 2 2 "Where in the world am I? Part 2" "RGvAGR" ]
    , [ img [ src "https://i.imgur.com/BtjZedW.jpg" ] [] ]
    , [ codepen 2 3 "Where in the world am I? Part 3" "JRxGbP" ]
    , [ codepen 2 4 "Where in the world am I? Part 4" "gwqGjQ" ]
    , [ codepen 2 5 "Where in the world am I? Part 5" "QKYyvA" ]
    , [ codepen 2 6 "Where in the world am I? Part 6" "jrdGJP" ]
    , [ h1 [] [ text "Take it to the limit" ] ]
    , [ codepen 3 1 "Where in the world is my coffee? Take 2" "mAvOXj" ]
    , [ codepen 3 2 "Where in the world is my coffee? Take 3" "JRxbBA" ]
    , [ codepen 3 3 "Where in the world is my coffee? Take 4" "ozmYmq" ]
    , [ h2 [] [ text "everything old is new again" ] ]
    , [ codepen 3 4 "Where in the world is my coffee?" "JRxbGb" ]
    , [ codepen 3 5 "Where in the world is my coffee? Take 5" "XjONQR" ]
    , [ h1 [] [ text "In closing" ]
      , ol []
            [ li [] [ text "Keep your functions short" ]
            , li [] [ text "Make third-parties do all the work" ]
            , li [] [ text "Handle your errors" ]
            ]
      ]
    , [ img [ src "https://assets.noodlesandwich.com/prodo.ai/logo/light.svg", alt "prodo.ai" ] []
      ]
    , [ h1 [] [ text "Fin." ]
      , h2 [] [ text "talks.samirtalwar.com" ]
      , h2 [] [ text "@SamirTalwar" ]
      , h2 [] [ text "prodo", span [ style [ ( "color", "#00e3a0" ) ] ] [ text ".ai" ] ]
      ]
    ]


lines : List String -> String
lines =
    String.join "\n"


data : String -> String -> Attribute message
data name =
    Html.Attributes.attribute ("data-" ++ name)


codepen : Int -> Int -> String -> String -> Html message
codepen major minor name slug =
    div [ class "codepen-container" ]
        [ p [] [ text (toString major ++ "." ++ toString minor) ]
        , p [ data "height" "400", data "theme-id" "0", data "slug-hash" slug, data "default-tab" "js,result", data "user" "SamirTalwar", data "embed-version" "2", class "codepen" ]
            [ text "See the Pen "
            , a [ href ("https://codepen.io/SamirTalwar/pen/" ++ slug ++ "/") ] [ text name ]
            , text " by Samir Talwar ("
            , a [ href "http://codepen.io/SamirTalwar" ] [ text "@SamirTalwar" ]
            , text ") on "
            , a [ href "http://codepen.io" ] [ text "CodePen" ]
            , text "."
            ]
        ]
