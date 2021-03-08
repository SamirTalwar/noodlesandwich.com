module Presentations.SmokeRewritingARubyProjectInHaskell exposing (main)

import Html exposing (..)
import Html.Attributes exposing (alt, class, href, src, style)
import NoodleSandwich.Slides as Slides


type Language
    = Plain
    | Haskell
    | Java
    | Ruby


main : Program () Slides.Model Slides.Message
main =
    Slides.program
        { title = "Smoke: Rewriting a Ruby project in Haskell for fun and type-safety"
        , slides = slides
        }


slides : Slides.Slides
slides =
    [ [ h1 [] [ small [] [ text "Smoke:" ], br [] [], text "Rewriting a Ruby project in Haskell for fun and type-safety" ]
      , h2 [] [ text "@SamirTalwar" ]
      , h2 []
            [ text "working on "
            , br [] []
            , a [ href "https://daml.com/" ] [ img [ src "https://assets.noodlesandwich.com/digital-asset/daml.svg", alt "DAML", style "height" "2em" ] [] ]
            ]
      , h3 []
            [ text "HaskellerZ, Zürich"
            , br [] []
            , text "2020-07-30T19:00:00+02:00"
            ]
      ]
    , [ p [] [ text "Nine years ago…" ]
      , hidden <| p [] [ text "I had a good problem." ]
      ]
    , [ p [] [ text "Nine years ago…" ]
      , p [] [ text "I had a good problem." ]
      ]
    , [ p [] [ text "And so, I decided to automate everything." ] ]
    , [ highlight Ruby
            [ "describe 'the difference between two dates, in days' do"
            , "  it 'should be 0 for the same date'"
            , "    result = Submission.run '2011-07-22' '2011-07-22'"
            , "    result should be 0"
            , "  end"
            , ""
            , "  it 'should be 1 for dates that are one day apart'"
            , "    result = Submission.run '2012-02-19' '2012-02-20'"
            , "    result should be 1"
            , "  end"
            , ""
            , "  it 'should report the correct figure for dates in the same month'"
            , "    result = Submission.run '2013-12-09' '2013-12-25'"
            , "    result should be 16"
            , "  end"
            , ""
            , "  it 'should correctly calculate across months'"
            , "    result = Submission.run '2014-04-25' '2014-05-05'"
            , "    result should be 10"
            , "  end"
            , ""
            , "  # You get the idea."
            , "end"
            ]
      ]
    , [ highlight Ruby
            [ "module Submission"
            , "  def run(*args)"
            , "    # Run the program, return STDOUT"
            , "  end"
            , "end"
            ]
      ]
    , [ p [] [ text "And then I went overboard." ] ]
    , [ p [ style "font-style" "italic" ] [ text "one-day.in:" ]
      , highlight Plain
            [ "2012-02-19"
            , "2012-02-20"
            ]
      , p [ style "font-style" "italic" ] [ text "one-day.out:" ]
      , highlight Plain
            [ "1"
            ]
      ]
    , [ h1 [] [ text "Introducing Smoke" ] ]
    , [ p [] [ img [ src "https://assets.noodlesandwich.com/talks/smoke--rewriting-a-ruby-project-in-haskell/screenshot.png", alt "Screenshot of Smoke", style "max-width" "100%" ] [] ] ]
    , [ highlight Ruby
            [ "#!/usr/bin/env ruby"
            , ""
            , "require 'rspec'"
            , ""
            , "TEST_CASE = ARGV.shift"
            , "APPLICATION = ARGV.shift"
            , ""
            , "RSpec::Matchers.define :be_one_of do |potential_values|"
            , "  potential_value_count = potential_values.length"
            , "  match do |actual|"
            , "    raise 'No outputs provided.' if potential_value_count == 0"
            , "    next potential_values[0] == actual if potential_value_count == 1"
            , "    potential_values.include? actual"
            , "  end"
            , ""
            , "  failure_message_for_should do |actual|"
            , "    next 'no outputs provided' if potential_value_count == 0"
            , "    next \"expected #{actual.inspect} to be #{potential_values[0].inspect}\" if potential_value_count == 1"
            , "    \"expected #{actual.inspect} to be one of #{potential_values.inspect}\""
            , "  end"
            , "end"
            , ""
            , "describe TEST_CASE do"
            , "  Dir.glob \"#{TEST_CASE}/*.in\" do |input_file|"
            , "    test = input_file[/(?<=#{TEST_CASE}\\/).*(?=\\.in)/]"
            , "    input = IO.read(input_file).strip"
            , "    output_files = Dir.glob \"#{TEST_CASE}/#{test}.out*\""
            , "    potential_outputs = output_files.collect do |output_file|"
            , "      IO.read(output_file).strip"
            , "    end"
            , ""
            , "    it \"handles the #{test} case\" do"
            , "      IO.popen APPLICATION, 'r+' do |io|"
            , "        io.write IO.read(input_file).strip"
            , "        io.read.strip.should be_one_of potential_outputs "
            , "      end"
            , "    end"
            , "  end"
            , "end"
            , ""
            , "RSpec::Core::Runner.run ['--color']"
            , ""
            ]
      ]
    , [ p [] [ text "6 years, 103 commits, and 269 lines later…" ] ]
    , [ p [] [ text "It was time for a change." ] ]
    , [ h1 [] [ text "#1: My $10 mistake" ] ]
    , [ p [] [ text "This is not OK." ]
      , highlight Java
            [ "Object x = new Object();"
            , "x = null;"
            ]
      ]
    , [ p [] [ text "This, however, is somehow legitimate." ]
      , highlight Ruby
            [ "x = 3"
            , "x = 'three'"
            , "x = nil"
            ]
      ]
    , [ p [] [ text "Which leads to code like this." ]
      , highlight Ruby
            [ "command ="
            , "  if command_override"
            , "    command_override"
            , "  elsif files[:command]"
            , "    files[:command][0].lines.collect(&:strip)"
            , "  elsif root_command"
            , "    root_command.lines.collect(&:strip)"
            , "  end"
            ]
      , hidden <| p [] [ text "Did you spot the bug?" ]
      ]
    , [ p [] [ text "Which leads to code like this." ]
      , highlight Ruby
            [ "command ="
            , "  if command_override"
            , "    command_override"
            , "  elsif files[:command]"
            , "    files[:command][0].lines.collect(&:strip)"
            , "  elsif root_command"
            , "    root_command.lines.collect(&:strip)"
            , "  end"
            ]
      , p [] [ text "Did you spot the bug?" ]
      ]
    , [ highlight Haskell
            [ "commandForLocation <-"
            , "  return commandFromOptions <<|>>"
            , "  readCommandFileIfExists (directory </> \"command\")"
            , "-- ... a little later ..."
            , "command <-"
            , "  sequence (readCommandFile <$> part FileTypes.Command) <<|>>"
            , "  return commandForLocation"
            , "-- where:"
            , "(<<|>>) = liftA2 (<|>)"
            ]
      ]
    , [ h1 [] [ text "#2: Just because it's built in, doesn't mean it's good." ] ]
    , [ highlight Haskell
            [ "data TestResult"
            , "  = TestSuccess Test"
            , "  | TestFailure TestExecutionPlan"
            , "                (PartResult Status)"
            , "                (PartResult StdOut)"
            , "                (PartResult StdErr)"
            , "  | TestError Test"
            , "              TestErrorMessage"
            , "  deriving (Eq, Show)"
            , ""
            , "newtype Status = Status { unStatus :: Int }"
            , "  deriving (Eq, Show)"
            , ""
            , "newtype StdIn = StdIn { unStdIn :: String }"
            , "  deriving (Eq, Show)"
            , ""
            , "newtype StdOut = StdOut { unStdOut :: String }"
            , "  deriving (Eq, Show)"
            , ""
            , "newtype StdErr = StdErr { unStdErr :: String }"
            , "  deriving (Eq, Show)"
            ]
      ]
    , [ p [] [ text "Cue frustration." ] ]
    , [ p [] [ text "Then headache." ] ]
    , [ p [] [ text "Next, anger." ] ]
    , [ p [] [ text "Finally, despair." ] ]
    , [ p [] [ text "Choices, choices." ]
      , p [] [ code [] [ text "String" ], text ", ", code [] [ text "ByteString" ], text ", ", code [] [ text "Text" ], text "…" ]
      , p [] [ code [] [ text "[a]" ], text ", ", code [] [ text "Vector a" ], text ", ", code [] [ text "Sequence a" ], text "…" ]
      ]
    , [ h1 [] [ text "#3: Let's talk about burritos" ] ]
    , [ h1 [] [ text "🌯" ] ]
    , [ p [] [ text "Exceptions are just monads." ] ]
    , [ highlight Haskell
            [ "executeTest"
            , "  :: ResolvedPath Dir"
            , "  -> TestPlan"
            , "  -> ExceptT SmokeExecutionError IO ActualOutputs"
            ]
      , hidden <| p [] [ text "Which I guess is something like:" ]
      , hidden <|
            highlight Haskell
                [ "executeTest"
                , "  :: ResolvedPath Dir"
                , "  -> TestPlan"
                , "  -> IO (Except SmokeExecutionError ActualOutputs)"
                ]
      ]
    , [ highlight Haskell
            [ "executeTest"
            , "  :: ResolvedPath Dir"
            , "  -> TestPlan"
            , "  -> ExceptT SmokeExecutionError IO ActualOutputs"
            ]
      , p [] [ text "Which I guess is something like:" ]
      , highlight Haskell
            [ "executeTest"
            , "  :: ResolvedPath Dir"
            , "  -> TestPlan"
            , "  -> IO (Except SmokeExecutionError ActualOutputs)"
            ]
      ]
    , [ highlight Haskell
            [ "executeTest"
            , "  :: ResolvedPath Dir"
            , "  -> TestPlan"
            , "  -> ExceptT SmokeExecutionError IO ActualOutputs"
            ]
      , p [] [ text "Which ", del [] [ text "I guess is something" ], text " ", ins [] [ text "is nothing" ], text " like:" ]
      , highlight Haskell
            [ "executeTest"
            , "  :: ResolvedPath Dir"
            , "  -> TestPlan"
            , "  -> IO (Except SmokeExecutionError ActualOutputs)"
            ]
      ]
    , [ p [] [ text "It turns out I still don't understand monads." ] ]
    , [ h1 [] [ text "#4: It's OK to love ", code [] [ text "IO" ] ] ]
    , [ highlight Haskell
            [ "main :: IO ()"
            , "main = do"
            , "  options <- parseOptions"
            , "  tests <- discoverTests options"
            , "  results <- runTests tests"
            , "  printResults options results"
            , "  printSummary options results"
            , "  exitAccordingTo results"
            , ""
            , "parseOptions :: IO Options"
            , ""
            , "discoverTests :: Options -> IO Tests"
            , ""
            , "runTests :: Tests -> IO TestResults"
            , ""
            , "printResults :: Options -> TestResults -> IO ()"
            , ""
            , "printResult :: Options -> TestResult -> IO ()"
            ]
      ]
    , [ highlight Haskell
            [ "run :: ReaderT AppOptions (ExceptT SmokeError IO) ()"
            ]
      ]
    , [ highlight Haskell
            [ "(actualExitCode, actualStdOut, actualStdErr) <-"
            , "    readProcessWithExitCode"
            , "      (fromJust executable) args (fromMaybe \"\" stdIn)"
            , "let actualStatus = convertExitCode actualExitCode"
            , "if actualStatus == expectedStatus &&"
            , "   actualStdOut `elem` expectedStdOuts &&"
            , "   actualStdErr `elem` expectedStdErrs"
            , "  then return $ TestSuccess test"
            , "  else return $ TestFailure test …"
            ]
      ]
    , [ p [] [ text "Duplication is far cheaper than the wrong abstraction." ]
      , cite [] [ text "Sandi Metz" ]
      ]
    , [ h1 [] [ text "#5: Types and scripting ", em [] [ text "can" ], text " go together!" ] ]
    , [ p [] [ text "Smoke is no longer a script." ] ]
    , [ h1 [] [ text "How to write Ruby" ]
      , p [] [ text "Make a small change, run the tests, and see what breaks." ]
      ]
    , [ h1 [] [ text "How to write Haskell" ]
      , p [] [ text "Make a tiny change, compile, and see what's affected." ]
      ]
    , [ p [] [ text "Haskell: it's better than a thousand lines of shell scripts." ] ]
    , [ h1 [] [ text "The best tool for the job" ] ]
    , [ p [] [ text "Haskell was the right choice for v2.0 of Smoke." ] ]
    , [ p [] [ text "But why?" ] ]
    , [ p [] [ text "Sometimes it's the money, sometimes it's the people, sometimes it's the free soda." ] ]
    , [ p [] [ text "And sometimes it's the language." ] ]
    , [ p [] [ text "Questions welcome." ]
      , p [] [ a [ href "https://github.com/SamirTalwar/smoke" ] [ text "https://github.com/SamirTalwar/smoke" ] ]
      , p [] [ a [ href "https://noodlesandwich.com/" ] [ text "https://noodlesandwich.com/" ] ]
      , p [] [ a [ href "https://daml.com/" ] [ text "https://", img [ src "https://assets.noodlesandwich.com/digital-asset/daml.svg", alt "daml", style "height" "1em" ] [], text ".com/" ] ]
      ]
    ]


hidden : Html a -> Html a
hidden element =
    div [ class "hidden" ] [ element ]


highlight : Language -> List String -> Html a
highlight language lines =
    let
        languageClass =
            case language of
                Plain ->
                    []

                Haskell ->
                    [ class "language-haskell" ]

                Java ->
                    [ class "language-java" ]

                Ruby ->
                    [ class "language-ruby" ]

        sizeStyle =
            if List.length lines > 20 then
                [ style "font-size" " 0.5em" ]

            else if List.length lines > 10 then
                [ style "font-size" " 0.75em" ]

            else
                []

        attributes =
            languageClass ++ sizeStyle
    in
    pre [] [ code attributes [ text (String.join "\n" lines) ] ]
