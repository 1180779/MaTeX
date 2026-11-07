(* Optional raw LaTeX cell support. Load with Get or Needs["MaTeX`Notebook`"]. *)
BeginPackage["MaTeX`Notebook`"];

CreateLaTeXNotebook::usage = "CreateLaTeXNotebook[] opens a notebook with an embedded LaTeX cell style.";
EnableLaTeXCells::usage = "EnableLaTeXCells[nb] adds the LaTeX cell style to an existing notebook.";
InsertLaTeXCell::usage = "InsertLaTeXCell[] inserts an editable raw LaTeX cell into the input notebook.";

Begin["`Private`"];

(* Make this checkout available to the current kernel without installing a paclet. *)
With[{root = DirectoryName[DirectoryName[$InputFileName]]},
  If[!MemberQ[$Path, root], AppendTo[$Path, root]]
];

latexStyle[] := Cell[StyleData["LaTeX", StyleDefinitions -> StyleData["Input"]],
  MenuSortingValue -> 1500,
  Evaluatable -> True, CellGroupingRules -> "InputGrouping",
  FormatType -> InputForm, DefaultFormatType -> InputForm,
  FontFamily -> Dynamic[AbsoluteCurrentValue[{StyleHints, "CodeFont"}]],
  ShowAutoStyles -> False,
  AutoQuoteCharacters -> {},
  CodeAssistOptions -> {"AutoPopupEnable" -> False},
  (* The evaluator is embedded, so viewing never depends on this helper package. *)
  CellEvaluationFunction -> Function[
    (If[!StringQ[#],
      Print["This cell contains two-dimensional notation. Replace its contents with raw LaTeX, such as $\\frac{1}{2}$."]; $Failed,
      If[Quiet[Check[Needs["MaTeX`"], $Failed]] === $Failed,
        Print["Install MaTeX, TeX and Ghostscript to render this cell. Saved output remains viewable."];
        $Failed,
        (* A paragraph box supplies text mode, wrapping, lists and display math
           inside MaTeX's math-mode renderer. Newlines protect closing braces from %. *)
        MaTeX`MaTeX["\\hbox{\\parbox{15cm}{\n" <>
          StringReplace[#, "\[IndentingNewLine]" -> "\n"] <> "\n}}", FontSize -> 16]
      ]
    ] &)[
      (* Evaluation input may already have whitespace stripped by the front end.
         Read the stored source instead, then flatten only text containers. *)
      (If[VectorQ[#, StringQ], StringJoin[#], $Failed] &)[
        Flatten[{
          If[TrueQ[$Notebooks],
            (If[MatchQ[#, _Cell], First[#], $Failed] &)[
              Quiet[Check[NotebookRead[EvaluationCell[]], $Failed]]
            ],
            #
          ] /. {BoxData -> List, RowBox -> List, TextData -> List}
        }]
      ]
    ]
  ]
];

stylesheet[existing_] := Replace[existing, {
  Notebook[cells_List, opts___] :> Notebook[
    Append[DeleteCases[cells, Cell[StyleData["LaTeX", ___], ___]], latexStyle[]], opts],
  other_ :> Notebook[{
    Cell[StyleData[StyleDefinitions -> Replace[other, Inherited -> "Default.nb"]]],
    latexStyle[]
  }, Visible -> False]
}];

EnableLaTeXCells[nb_NotebookObject] := SetOptions[nb,
  StyleDefinitions -> stylesheet[StyleDefinitions /. Options[nb, StyleDefinitions]]
];

InsertLaTeXCell[nb_NotebookObject] := (
  EnableLaTeXCells[nb];
  NotebookWrite[nb, Cell["", "LaTeX"], All]
);
InsertLaTeXCell[] := InsertLaTeXCell[InputNotebook[]];

CreateLaTeXNotebook[] := CreateDocument[Notebook[{
  Cell["LaTeX cells", "Title"],
  Cell["Choose LaTeX from the cell style menu. Write ordinary LaTeX text, using $...$ for inline math and \\[...\\] or equation environments for display math, then press Shift+Enter. Source and rendered output are saved in this notebook. Rendering requires MaTeX, TeX and Ghostscript; viewing saved graphics does not.", "Text"],
  Cell["\\textbf{Maxwell's equations}\n\nHere $\\rho$ is the charge density.\n\\[\n\\begin{aligned}\n  \\nabla \\cdot \\mathbf{E} &= \\frac{\\rho}{\\varepsilon_0} \\\\\n  \\nabla \\cdot \\mathbf{B} &= 0\n\\end{aligned}\n\\]\n\nA new paragraph starts after a blank line.", "LaTeX"]
}, StyleDefinitions -> stylesheet["Default.nb"]]];

End[];
EndPackage[];
