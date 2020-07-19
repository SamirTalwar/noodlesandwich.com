module NoodleSandwich.Slides exposing
    ( Data
    , Message
    , Model
    , SlideNo
    , Slides
    , program
    )

import Browser
import Browser.Events
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (alt, class, href, id, src, style)
import Html.Events exposing (..)
import Json.Decode
import String
import Task
import Url exposing (Url)


program : Data -> Program () Model Message
program data =
    Browser.application
        { init = init data.slides
        , update = update
        , view = view data.title
        , subscriptions = subscriptions
        , onUrlChange = onUrlChange
        , onUrlRequest = onUrlRequest
        }


type alias Data =
    { title : String, slides : Slides }


type Model
    = Model Navigation.Key Slides SlideNo


type Message
    = Next
    | Previous
    | GoTo SlideNo
    | NoMessage


type alias Slides =
    List Slide


type alias Slide =
    List (Html Message)


type alias SlideNo =
    Int


subscriptions : model -> Sub Message
subscriptions =
    always <|
        Browser.Events.onKeyUp <|
            Json.Decode.map
                (\key ->
                    case key of
                        -- space
                        " " ->
                            Next

                        "ArrowRight" ->
                            Next

                        "ArrowLeft" ->
                            Previous

                        _ ->
                            NoMessage
                )
            <|
                Json.Decode.field "key" Json.Decode.string


parseLocation : Url -> Message
parseLocation url =
    GoTo <| Maybe.withDefault 0 <| Maybe.andThen String.toInt <| url.fragment


init : Slides -> () -> Url -> Navigation.Key -> ( Model, Cmd Message )
init slides _ url key =
    ( Model key slides 0
    , Task.perform onUrlChange (Task.succeed url)
    )


onUrlChange : Url -> Message
onUrlChange url =
    GoTo <| Maybe.withDefault 0 <| Maybe.andThen String.toInt <| url.fragment


onUrlRequest : Browser.UrlRequest -> Message
onUrlRequest urlRequest =
    case urlRequest of
        Browser.Internal url ->
            onUrlChange url

        Browser.External _ ->
            NoMessage


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    let
        (Model key slides current) =
            model
    in
    case message of
        Next ->
            if current < List.length slides - 1 then
                ( Model key slides (current + 1)
                , Navigation.pushUrl key ("#" ++ String.fromInt (current + 1))
                )

            else
                ( model
                , Cmd.none
                )

        Previous ->
            if current > 0 then
                ( Model key slides (current - 1)
                , Navigation.pushUrl key ("#" ++ String.fromInt (current - 1))
                )

            else
                ( model
                , Cmd.none
                )

        GoTo destination ->
            ( Model key slides destination
            , Cmd.none
            )

        NoMessage ->
            ( model
            , Cmd.none
            )


view : String -> Model -> Browser.Document Message
view title model =
    { title = title, body = [ body model ] }


body : Model -> Html Message
body (Model _ slides currentSlideIndex) =
    div [ id "presentation", class "talk presentation elm" ]
        [ div
            [ class "app", onClick Next ]
            (List.map2 (slide currentSlideIndex) (List.range 0 (List.length slides)) slides)
        ]


slide : SlideNo -> SlideNo -> Slide -> Html Message
slide currentSlideIndex slideIndex =
    if currentSlideIndex == slideIndex then
        div [ class "slide" ]

    else
        div [ class "another slide" ]
