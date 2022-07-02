% This is syllabus class for creating syllabi for Irkutsk State University
% Passing options to latex file https://stackoverflow.com/questions/1465665/passing-command-line-arguments-to-latex-document/1466610#1466610
% https://tex.stackexchange.com/questions/74941/add-option-to-class-with-command


% Key values examples
% https://tex.stackexchange.com/questions/557894/how-to-use-keyword-arguments-in-a-latex-environment

% LUA libraries
% https://github.com/1bardesign/batteries batteries

% https://github.com/mauriciobomfim/lua-activerdf  ActiveRdf

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{syllabus}[2022/06/30 Syllabus LaTeX class by Irkutsk State University]
\RequirePackage{luacode}
\luadirect{syll = require('syllabus')}
\RequirePackage{xparse}

\DeclareOption{rdf}{\OptionNotUSed}%will be used for writing down RDF in a file
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{scrartcl}}
\ProcessOptions\relax

\LoadClass[12pt]{scrartcl}% Koma script article


\RequirePackage{tabularx}
\RequirePackage{indentfirst}
\RequirePackage{polyglossia}
\RequirePackage{graphicx}
\RequirePackage[dvipsnames]{xcolor}
\RequirePackage{multirow}
\RequirePackage{tabularray}
\setmainlanguage{russian}
\setotherlanguage{english}
\setkeys{russian}{babelshorthands=true} % Переносы типа
                                        % красно"=зеленый
\RequirePackage{hyperref}
\hypersetup{
    colorlinks=true,
    linkcolor=black,
    filecolor=black,
    urlcolor=black,
    pdftitle={Рабочая программа курса ИМИТ ИГУ},
    % pdfpagemode=FullScreen,
    }

\RequirePackage{luatextra}
\RequirePackage{unicode-math}
\defaultfontfeatures{Scale=MatchLowercase,Numbers=Lining,Ligatures=TeX}
\RequirePackage{microtype}
\SetProtrusion
    [name=std]
    {
      encoding={utf8},
      family=*}
    {
    « = {300,     },
    » = {    , 300},
    „ = {300,     },
    “ = {    , 300},
    ( = {300,     },
    ) = {    , 300},
    ! = {    , 300},
    ? = {    , 300},
    : = {    , 300},
    ; = {    , 300},
    . = {    , 300},
    - = {    , 300},
   {,}= {    , 300}
 }
 \microtypesetup{protrusion=true,expansion=true}

\DefTblrTemplate{contfoot-text}{default}{продолжение таблицы на следующей странице}
\DefTblrTemplate{conthead-text}{default}{(продолжение)}

\DefTblrTemplate{caption}{default}{}
\DefTblrTemplate{capcont}{default}{}

\setmainfont{Times New Roman}
\setsansfont{Fira Mono}
\setmonofont{Fira Code}[
     Scale=MatchLowercase,
     Numbers=SlashedZero,
     Ligatures=TeX,
     Numbers=Lining]
\newfontfamily{\cyrillicfonttt}{Fira Code}[
     Scale=MatchLowercase,
     Numbers=SlashedZero,
     Ligatures=TeX,
     Numbers=Lining]
\newfontfamily{\cyrillicfont}{Times New Roman}[
     Scale=MatchLowercase,
     Numbers=SlashedZero,
     Ligatures=TeX,
     Numbers=Lining]
\newfontfamily{\cyrillicfontsf}{Fira Mono}[
     Scale=MatchLowercase,
     Numbers=SlashedZero,
     Ligatures=TeX,
     Numbers=Lining]


     \RedeclareSectionCommand[%
     font=\large\rmfamily\bfseries
     ]{section}
     \RedeclareSectionCommand[%
     font=\rmfamily\bfseries
     ]{subsection}
     \RedeclareSectionCommand[%
     font=\normalsize\rmfamily\bfseries
     ]{subsubsection}
     \RedeclareSectionCommand[%
     font=\normalsize\rmfamily\bfseries
     ]{paragraph}
     \DeclareTOCStyleEntry{dottedtocline}{section}


% \renewcommand\sectionlinesformat[4]{%
%   \@hangfrom{\hskip #2#3}{\MakeUppercase{#4}}%
% }

%\renewcommand{\sectioncatchphraseformat}[4]{%
%  \hskip #2#3\MakeUppercase{#4}%
%}

     \setlength{\parindent}{1cm}
     \setcounter{tocdepth}{\subsectiontocdepth}

     \newcommand{\rdf}[2]{#2}
     \newenvironment{rdfctx}[1]{}{}
     \renewcommand{\paragraph}[1]{\par\textbf{#1}}

% \directlua {
%   local t = lua.get_functions_table()
%   t[1] = function() tex.print("!") end
%   t[2] = function() tex.print("?") end
% }
%\luafunc1


\ExplSyntaxOn

\newcounter{syll@item}

\def\theitem{\arabic{syll@item}}

\NewDocumentEnvironment{SyllabusValidation}{m}
{
  \begingroup
  \bfseries \color{red} #1:
  \normalfont
  \begin{enumerate}
}
{
  \end{enumerate}
  \endgroup
}


\NewDocumentEnvironment{syll@item}{O{}m}
{
  \refstepcounter{syll@item}
  \let\oldtheenumi=\theenumi
  \RenewDocumentCommand{\theenumi}{}{\theitem.\arabic{enumi}}
  \directlua{
    syll.item = syll.Item:new{index=\theitem, title=\luastring{#2}}
  }
  \keys_set:nn { syllabus/item } { #1 }
  \directlua{
    syll.items:addItem(syll.item)
  }
}
{
  \let\theenumi=\oldtheenumi
  \let\oldtheenumi=\relax
}

\keys_define:nn { syllabus/item }
{
  lec .code:n = \luadirect{syll.item:setValue('lec', \luastring{#1})},
  lec .default:n = nil,
  lab .code:n = \luadirect{syll.item:setValue('lab', \luastring{#1})},
  lab .default:n = nil,
  sem .code:n = \luadirect{syll.item:setValue('sem', \luastring{#1})},
  sem .default:n = nil,
  per .code:n = \luadirect{syll.item:setValue('per', \luastring{#1})},
  per .default:n = nil,
  control .code:n = \luadirect{syll.item:setValue('control', \luastring{#1}, syll.items)},
  control .default:n = nil,
  type .code:n = \luadirect{syll.item:setType(\luastring{#1}, syll.items)},
  type .default:n = nil,
  term .code:n = \luadirect{syll.item:setTerm(\luastring{#1}, syll.items)},
  term .default:n = nil,
  itemname .code:n = \def\itemname{\luastring{#1}},
  itemname .default:n = {Тема},
  label .code:n = \luadirect{syll.item:setValue('label', \luastring{#1})},
  label .default:n = undefined,
  comp .code:n = \luadirect{syll.item:setValue('comp', \luastring{#1})},
  comp .default:n = nil,
  name .code:n = \luadirect{syll.item:setName(\luastring{#1}, syll.items) },
  name .default:n = nil,
  hours .code:n = \luadirect{syll.item:setValue('hours', \luastring{#1})},
  hours .default:n = nil,
  topics .code:n = \luadirect{syll.item:setValue('topics', \luastring{#1})},
  topics .default:n = {}
}

\NewDocumentEnvironment{syll@items}{O{}}
{
  \setcounter{syll@item}{0}
  \directlua{
    syll.items = syll.Item:new{}
    syll.items:asItems()
    syll.item = syll.items
  }
  \keys_set:nn { syllabus/item } { #1 }
}
{
  \directlua{syll.items = nil; syll.item = nil}
  % TODO: DUMP?
}

\NewDocumentEnvironment{topics}{O{}}
{
  \def\itemname{Тема}
  \begin{syll@items}[#1]
    \begin{rdfctx}{\rdfsetctx{list}{syll wpdd:itemList !wpdd:TopicList !wpdd:ItemList \luadirect{syll.Item:sprintRDFType()}}}
}
{
  \luadirect{syll.items:topicValidation()}
  % \luadirect{syll.saveState('\jobname' .. '.json')}
  \luadirect{syll.items:generateContentByTopic()}
    \end{rdfctx}
  \end{syll@items}
}

\NewDocumentEnvironment{topic}{O{}mb}
{
  {\bfseries \itemname\ \rdf{item dcterms:identifier}{\protect\theitem}.~\rdf{item rdfs:label}{#2}}\par
  \begin{rdfctx}{\rdfsetctx{item}{list ^schema:member !wpdd:ListItem !wpdd:Topic}}
  \begin{syll@item}[#1]{#2}
  #3
}
{
  \end{syll@item}
  \end{rdfctx}
}


% \def\workname{Лабораторная работа}
\def\workheaderstyle{\normalfont\em}
\def\worktitlestyle{\normalfont}

\NewDocumentEnvironment{rdfenv}{O{}m}{}{}

\NewDocumentEnvironment{works}{O{}}
{
  \def\itemname{Работа студента}
  \begin{syll@items}[#1]
  \luadirect{
    syll.items:sprintItemName()
  }
  \begin{rdfctx}{\rdfsetctx{list}{syll wpdd:itemList !wpdd:ExampleList !wpdd:CurrentAttestation !wpdd:ItemList}}
  \def\syllabus@worktype{wpdd:LaboratoryWork}
}
{
  \luadirect{
    syll.items:workValidation()
  }
\end{rdfctx}
\end{syll@items}
}

\NewDocumentEnvironment{work}{O{}m}
{
  \def\itemname{Работа}
  \begin{syll@item}[#1]{#2}
  \begin{rdfenv}{list ^schema:member !wpdd:ListItem !wpdd:Example }
  \paragraph{{\workheaderstyle \itemname\ \theitem.}~{\worktitlestyle #2}}
}
{
\end{rdfenv}\par\vspace{1em}
\end{syll@item}
}


\AtEndPreamble{
%
\rdf{%
  \rdfsetctx{syll}{wpdb:_}%
  % \rdfsetctx{common}{wpdb:_}%
  \gdef{\syll@contentbytopic}{\@rerun}
}{}
}

\ExplSyntaxOff

\AtBeginDocument{
  %\@input{\jobname.syll}
  %\luadirect{syll.Topics:openFile('\jobname' .. '.syll')}
}

\AtEndDocument{
  \luadirect{syll.closeFile('cbt')}
}

\def\syll@rerun{\par{\color{red}Требуется повторный запуск \LuaLaTeX}}

\NewDocumentCommand{\contentbytopic}{}{%
  \noindent{\footnotesize{}\@input{\jobname.cbt}}
  \luadirect{syll.openFile('\jobname','cbt')}
}
