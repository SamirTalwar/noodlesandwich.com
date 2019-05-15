module NoodleSandwich.Slides exposing
    ( Data
    , Message
    , Model
    , SlideNo
    , Slides
    , program
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
    | GoTo SlideNo
    | NoMessage


type alias Slides =
    List (List (Html Message))


type alias SlideNo =
    Int


subscriptions : model -> Sub Message
subscriptions =
    always <|
        Sub.batch
            [ Keyboard.presses
                (\n ->
                    case n of
                        -- right arrow
                        39 ->
                            Next

                        -- left arrow
                        37 ->
                            Previous

                        _ ->
                            NoMessage
                )
            , Keyboard.ups
                (\n ->
                    case n of
                        -- space
                        32 ->
                            Next

                        _ ->
                            NoMessage
                )
            ]


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

        GoTo slide ->
            Model slides slide ! []

        NoMessage ->
            model ! []


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
