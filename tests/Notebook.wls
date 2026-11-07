root = DirectoryName[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root, "MaTeX", "Notebook.m"}]];
Needs["MaTeX`"];
style = MaTeX`Notebook`Private`latexStyle[];
sheet = MaTeX`Notebook`Private`stylesheet;
source = "\\begin{aligned}\nx &= \\frac{1}{2} \\\\\ny &= 3\n\\end{aligned}";
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
    {Head[callback[source]], received}, {Graphics, source},
    TestID -> "raw source reaches renderer without parsing or slash changes"]];
  AppendTo[tests, VerificationTest[
    Quiet[callback[BoxData["x"]]], $Failed,
    TestID -> "rejects non-text input"]];
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
Put[starter, FileNameJoin[{root, "examples", "LaTeXCells.nb"}]];
report = TestReport[tests];
Print["Passed: ", report["TestsSucceededCount"], "; failed: ", report["TestsFailedCount"]];
Scan[If[#["Outcome"] =!= "Success", Print[{#["TestID"], #["ActualOutput"]}]] &,
  Values[report["TestResults"]]];
Quit[If[report["TestsFailedCount"] === 0, 0, 1]];
