module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Random


main : Program Never Model Msg
main =
    Html.program
        { init = createModel newScore
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type Model
    = Playing Score Deck
    | Guessing Score Deck Card
    | MatchCard Score Deck Card Card
    | GameOver Score Deck


type Msg
    = NoOp
    | Shuffle (List Int)
    | Flip Card
    | Reset


type alias Card =
    { id : String
    , group : Group
    , flipped : Bool
    }


type Group
    = A
    | B


type alias Deck =
    List Card


type alias Score =
    { current : Int
    , best : Maybe Int
    }


cards : List String
cards =
    [ "dinosaur"
    , "8-ball"
    , "baked-potato"
    , "kronos"
    , "rocket"
    , "skinny-unicorn"
    , "that-guy"
    , "zeppelin"
    ]


newScore : Score
newScore =
    { current = 0
    , best = Nothing
    }


createModel : Score -> ( Model, Cmd Msg )
createModel score =
    let
        model =
            Playing score deck

        cmd =
            randomList Shuffle (List.length deck)
    in
        ( model, cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        Reset ->
            let
                updateBest s =
                    case s.best of
                        Nothing ->
                            { s | best = Just s.current }

                        Just n ->
                            if s.current < n then
                                { s | best = Just s.current }
                            else
                                s

                resetCurrent s =
                    { s | current = 0 }
            in
                getScore model |> updateBest |> resetCurrent |> createModel

        Shuffle ns ->
            let
                newDeck =
                    shuffleDeck deck ns
            in
                Playing (getScore model) newDeck ! []

        Flip card ->
            if card.flipped then
                model ! []
            else
                checkIfCorrect card model


view : Model -> Html Msg
view model =
    case model of
        Playing _ deck ->
            game deck

        Guessing _ deck _ ->
            game deck

        MatchCard _ deck _ _ ->
            game deck

        GameOver score deck ->
            wrapper deck (playAgainOverlay score)


wrapper : Deck -> Html Msg -> Html Msg
wrapper deck overlay =
    div [ class "wrapper" ]
        [ div [] (List.map createCard deck)
        , overlay
        ]


game : Deck -> Html Msg
game deck =
    wrapper deck (text "")


cardClass : Card -> String
cardClass card =
    "card-" ++ card.id


createCard : Card -> Html Msg
createCard card =
    div [ class "container" ]
        [ div
            [ classList [ ( "flipped", card.flipped ), ( "card", True ) ]
            , onClick (Flip card)
            ]
            [ div [ class "card-back" ] []
            , div [ "front " ++ cardClass card |> class ] []
            ]
        ]


playAgainOverlay : Score -> Html Msg
playAgainOverlay score =
    div [ class "congrats" ]
        [ p [] [ text "Yay! You win!" ]
        , viewScore score
        , text "Do you want to "
        , span [ onClick Reset ] [ text "play again?" ]
        ]


viewScore : Score -> Html Msg
viewScore score =
    let
        bestScore =
            case score.best of
                Nothing ->
                    text ""

                Just n ->
                    p []
                        [ text "Your best score is "
                        , text (toString n)
                        , text " turns"
                        ]
    in
        div []
            [ p []
                [ text "You completed in "
                , text (toString score.current)
                , text " turns"
                ]
            , bestScore
            ]


initCard : Group -> String -> Card
initCard group name =
    { id = name
    , group = group
    , flipped = False
    }


deck : Deck
deck =
    let
        groupA =
            List.map (initCard A) cards

        groupB =
            List.map (initCard B) cards
    in
        List.concat [ groupA, groupB ]


randomList : (List Int -> Msg) -> Int -> Cmd Msg
randomList msg len =
    Random.int 0 100
        |> Random.list len
        |> Random.generate msg


shuffleDeck : Deck -> List comparable -> Deck
shuffleDeck deck xs =
    List.map2 (,) deck xs
        |> List.sortBy Tuple.second
        |> List.unzip
        |> Tuple.first


flip : Bool -> Card -> Card -> Card
flip isFlipped a b =
    if (a.id == b.id) && (a.group == b.group) then
        { b | flipped = isFlipped }
    else
        b


checkIfCorrect : Card -> Model -> ( Model, Cmd Msg )
checkIfCorrect card model =
    case model of
        Playing score deck ->
            let
                newDeck =
                    List.map (flip True card) deck
            in
                Guessing score newDeck card ! []

        Guessing score deck guess ->
            let
                newDeck =
                    List.map (flip True card) deck

                isOver =
                    List.all .flipped newDeck

                incrementScore =
                    { score | current = score.current + 1 }

                newModel =
                    if isOver then
                        GameOver score newDeck
                    else
                        MatchCard incrementScore newDeck guess card
            in
                newModel ! []

        MatchCard score deck guess1 guess2 ->
            if guess1.id == guess2.id then
                update (Flip card) (Playing score deck)
            else
                let
                    flipGuess =
                        flip False guess1 >> flip False guess2

                    newDeck =
                        List.map flipGuess deck
                in
                    Playing score newDeck ! []

        GameOver score deck ->
            GameOver score deck ! []


getScore : Model -> Score
getScore model =
    case model of
        Playing score _ ->
            score

        Guessing score _ _ ->
            score

        MatchCard score _ _ _ ->
            score

        GameOver score _ ->
            score
