module NoodleSandwich.Slides
    exposing
        ( program
        , Data
        , Message
        , Model
        , SlideNo
        , Slides
        )

import Html exposing (..)
import Html.Attributes exposing (alt, class, href, src, style)
import Html.Events exposing (..)
import Keyboard
import Navigation
import String
import Task


program : Data -> Program Never Model Message
program data =
    Navigation.program parseLocation
        { init = init data.slides
        , update = update
        , view = view data.extraHtml
        , subscriptions = subscriptions
        }


type alias Data =
    { slides : Slides, extraHtml : List (Html Message) }


type Model
    = Model Slides SlideNo


type Message
    = Next
    | Previous
    | KeyPress Int
    | GoTo SlideNo


type alias Slides =
    List (List (Html Message))


type alias SlideNo =
    Int


subscriptions : model -> Sub Message
subscriptions =
    always (Keyboard.presses KeyPress)


parseLocation : Navigation.Location -> Message
parseLocation location =
    GoTo <| Result.withDefault 0 <| String.toInt (String.dropLeft 1 location.hash)


init : Slides -> Navigation.Location -> ( Model, Cmd Message )
init slides location =
    Model slides 0 ! [ Task.perform parseLocation (Task.succeed location) ]


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    let
        (Model slides currentSlide) =
            model
    in
        case message of
            Next ->
                if currentSlide < List.length slides - 1 then
                    Model slides (currentSlide + 1)
                        ! [ Navigation.newUrl ("#" ++ toString (currentSlide + 1))
                          ]
                else
                    model ! []

            Previous ->
                if currentSlide > 0 then
                    Model slides (currentSlide - 1)
                        ! [ Navigation.newUrl ("#" ++ toString (currentSlide - 1))
                          ]
                else
                    model ! []

            KeyPress 39 ->
                model ! [ Task.succeed Next |> Task.perform identity ]

            KeyPress 37 ->
                model ! [ Task.succeed Previous |> Task.perform identity ]

            KeyPress _ ->
                model ! []

            GoTo slide ->
                Model slides slide ! []


view : List (Html Message) -> Model -> Html Message
view extraHtml (Model slides currentSlide) =
    div [ class "app", onClick Next ]
        (List.map2
            (\slideIndex slide ->
                div
                    (if currentSlide == slideIndex then
                        [ class "slide" ]
                     else
                        [ class "slide", style [ ( "display", "none" ) ] ]
                    )
                    slide
            )
            (List.range 0 (List.length slides))
            slides
            ++ extraHtml
        )
