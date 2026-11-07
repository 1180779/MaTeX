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
  FontFamily -> "Source Code Pro", ShowAutoStyles -> False,
  AutoQuoteCharacters -> {},
  CodeAssistOptions -> {"AutoPopupEnable" -> False},
  (* The evaluator is embedded, so viewing never depends on this helper package. *)
  CellEvaluationFunction -> Function[
    If[!StringQ[#],
      Print["LaTeX cells require plain text input."]; $Failed,
      If[Quiet[Check[Needs["MaTeX`"], $Failed]] === $Failed,
        Print["Install MaTeX, TeX and Ghostscript to render this cell. Saved output remains viewable."];
        $Failed,
        MaTeX`MaTeX[#, FontSize -> 16]
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
  Cell["Choose LaTeX from the cell style menu. Write raw math-mode LaTeX (single backslashes, no dollar delimiters), then press Shift+Enter. Source and rendered output are saved in this notebook. Rendering requires MaTeX, TeX and Ghostscript; viewing saved graphics does not.", "Text"],
  Cell["\\begin{aligned}\n  \\nabla \\cdot \\mathbf{E} &= \\frac{\\rho}{\\varepsilon_0} \\\\\n  \\nabla \\cdot \\mathbf{B} &= 0\n\\end{aligned}", "LaTeX"]
}, StyleDefinitions -> stylesheet["Default.nb"]]];

End[];
EndPackage[];
