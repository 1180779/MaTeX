root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "MaTeX", "Notebook.m"}]];
Needs["MaTeX`"];
style = MaTeX`Notebook`Private`latexStyle[];
sheet = MaTeX`Notebook`Private`stylesheet;
source = "\\textbf{Energy notes}\n\nInline math: $E=mc^2$.\n\n\\begin{equation}E=mc^2\\end{equation}\n\\[\\begin{aligned}x &= \\frac{1}{2} \\\\ y &= 3\\end{aligned}\\]\n\\begin{itemize}\\item First item\\item Second item\\end{itemize}\nA final comment % closing braces must stay on a fresh line";
wrapped = "\\hbox{\\parbox{15cm}{\n" <> source <> "\n}}";
styleOptions = Cases[List @@ style, _Rule | _RuleDelayed];
callback = CellEvaluationFunction /. styleOptions;
tests = {};
AppendTo[tests, VerificationTest[
  {FormatType, DefaultFormatType, Evaluatable} /. styleOptions,
  {InputForm, InputForm, True}, TestID -> "raw cells use evaluatable plain text"]];
Internal`InheritedBlock[{MaTeX`MaTeX},
  Unprotect[MaTeX`MaTeX]; Clear[MaTeX`MaTeX];
  MaTeX`MaTeX[text_String, ___] := (received = text; Graphics[Disk[]]);
  AppendTo[tests, VerificationTest[
    {Head[callback[source]], received}, {Graphics, wrapped},
    TestID -> "note source is wrapped in a text paragraph without parsing or slash changes"]];
  AppendTo[tests, VerificationTest[
    {Head[callback[BoxData[source]]], received}, {Graphics, wrapped},
    TestID -> "accepts boxed text from an existing Input cell"]];
  AppendTo[tests, VerificationTest[
    callback[BoxData[RowBox[{"\\frac", RowBox[{"{", "1", "}"}], "{2}",
      "\[IndentingNewLine]", "x^2"}]]]; received,
    "\\hbox{\\parbox{15cm}{\n\\frac{1}{2}\nx^2\n}}", TestID -> "joins nested text boxes and preserves line breaks"]];
  AppendTo[tests, VerificationTest[
    callback[BoxData["Quit[]"]]; received, "\\hbox{\\parbox{15cm}{\nQuit[]\n}}",
    TestID -> "boxed source is passed as text rather than evaluated"]];
  AppendTo[tests, VerificationTest[
    callback[BoxData[FractionBox["1", "2"]]], $Failed,
    TestID -> "rejects two-dimensional notation rather than silently flattening it"]];
  Internal`InheritedBlock[{NotebookRead, EvaluationCell},
    Unprotect[NotebookRead, EvaluationCell]; Clear[NotebookRead, EvaluationCell];
    EvaluationCell[] := CellObject["source"];
    NotebookRead[_] := Cell[BoxData[RowBox[{"Hello", "  ", "world", "\n\n",
      "Inline math: $x + y$."}]], "LaTeX"];
    AppendTo[tests, VerificationTest[
      Block[{$Notebooks = True}, callback[BoxData[RowBox[{"Hello", "world"}]]]];
      received,
      "\\hbox{\\parbox{15cm}{\nHello  world\n\nInline math: $x + y$.\n}}",
      TestID -> "stored cell preserves spaces and paragraphs lost from evaluation input"]];
    NotebookRead[_] := Cell[TextData[{"Hello ", "world"}], "LaTeX"];
    AppendTo[tests, VerificationTest[
      Block[{$Notebooks = True}, callback["Helloworld"]]; received,
      "\\hbox{\\parbox{15cm}{\nHello world\n}}",
      TestID -> "text cell source also preserves word separation"]];
  ];
];
(* Compile the exact paragraph wrapper with MaTeX's real document template.
   This exercises LaTeX itself without the unavailable headless PDF importer. *)
compileDir = CreateDirectory[];
texDocument = MaTeX`Private`$template[<|
  "preamble" -> StringRiffle["BasePreamble" /. Options[MaTeX`MaTeX], "\n"],
  "tex" -> "\\MaTeX{" <> wrapped <> "}", "display" -> "\\displaystyle",
  "strut" -> "\\strut", "fontsize" -> 16, "skipsize" -> 19.2|>];
texFile = Export[FileNameJoin[{compileDir, "note.tex"}], texDocument, "Text"];
compiled = RunProcess[{"pdflatex", "-halt-on-error", "-interaction=nonstopmode", texFile},
  ProcessDirectory -> compileDir, ProcessEnvironment -> MaTeX`Private`$environment];
AppendTo[tests, VerificationTest[compiled["ExitCode"], 0,
  TestID -> "real LaTeX compiles prose, inline math, display math, equations, lists and final comment"]];
If[compiled["ExitCode"] === 0,
  pdfText = RunProcess[{"pdftotext", FileNameJoin[{compileDir, "note.pdf"}], "-"}]["StandardOutput"];
  AppendTo[tests, VerificationTest[And @@ (StringContainsQ[pdfText, #] & /@
    {"Energy notes", "Inline math", "First item", "Second item"}), True,
    TestID -> "compiled PDF contains note text and list items"]];
  DeleteDirectory[compileDir, DeleteContents -> True],
  Print["LaTeX artifacts retained at ", compileDir, ": ", compiled["StandardOutput"]]
];
custom = Cell[StyleData["MyHeading"], FontSize -> 22];
embedded = sheet[Notebook[{Cell[StyleData[StyleDefinitions -> "Default.nb"]], custom}]];
AppendTo[tests, VerificationTest[
  {Count[embedded, custom, Infinity], Count[sheet[embedded], StyleData["LaTeX", ___], Infinity]},
  {1, 1}, TestID -> "existing styles survive and repeated enabling is idempotent"]];
AppendTo[tests, VerificationTest[
  FreeQ[embedded, symbol_Symbol /; Context[symbol] === "MaTeX`Notebook`Private`"],
  True, TestID -> "embedded style has no helper dependencies"]];
(* Ordinary graphics stand in for a render: this check needs no PDF importer. *)
document = Notebook[{Cell[CellGroupData[{
  Cell[source, "LaTeX"], Cell[BoxData[ToBoxes[Graphics[Disk[]]]], "Output"]
}, Open]]}, StyleDefinitions -> embedded];
temp = CreateTemporary[];
Put[document, temp]; restored = Get[temp]; DeleteFile[temp];
AppendTo[tests, VerificationTest[
  {restored === document, Count[restored, _GraphicsBox, Infinity], Count[restored, source, Infinity]},
  {True, 1, 1}, TestID -> "saved notebook retains source, graphics and stylesheet"]];
(* Write the starter as a standard notebook expression; no front end is required. *)
Internal`InheritedBlock[{CreateDocument},
  Unprotect[CreateDocument]; Clear[CreateDocument]; CreateDocument[nb_Notebook] := nb;
  starter = MaTeX`Notebook`CreateLaTeXNotebook[];
];
Export[FileNameJoin[{root, "examples", "LaTeXCells.nb"}],
  ToString[starter, InputForm, PageWidth -> Infinity], "Text"];
report = TestReport[tests];
Print["Passed: ", report["TestsSucceededCount"], "; failed: ", report["TestsFailedCount"]];
Scan[If[#["Outcome"] =!= "Success", Print[{#["TestID"], #["ActualOutput"]}]] &,
  Values[report["TestResults"]]];
Quit[If[report["TestsFailedCount"] === 0, 0, 1]];
