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


\NewDocumentEnvironment{syll@item@base}{O{}m}
{
  \directlua{
    syll.item = syll.Item:new{index=\theitem, title=\luastring{#2}, term=syll.items.term}
  }
  \keys_set:nn { syllabus/item } { #1 }
  \directlua{
    syll.items:addItem(syll.item)
    syll.item:startReading()
  }
}{
  \directlua{
    syll.item:stopReading()
  }
}

\NewDocumentEnvironment{syll@item}{O{}m}
{
  \refstepcounter{syll@item}
  \let\oldtheenumi=\theenumi
  \RenewDocumentCommand{\theenumi}{}{\theitem.\arabic{enumi}}
  \begin{syll@item@base}[#1]{#2}
}
{
  \end{syll@item@base}
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
  type .code:n = \luadirect{syll.item:setType(\luastring{#1}, nil, syll.items)},
  type .default:n = nil,
  rdftype .code:n = \luadirect{syll.item:setValue('rdftype', {#1})},
  rdftype .default:n = nil,
  term .code:n = \luadirect{syll.item:setTerm(\luastring{#1}, syll.items)},
  term .default:n = nil,
  itemname .code:n = \def\itemname{#1} \luadirect{syll.item:setItemName(\luastring{\itemname}, syll.items)},
  itemname .default:n = {Тема},
  label .code:n = \luadirect{syll.item:setValue('label', \luastring{#1})},
  label .default:n = undefined,
  comp .code:n = \luadirect{syll.item:setValue('comp', \luastring{#1})},
  comp .default:n = nil,
  name .code:n = \luadirect{syll.item:setValue('name', \luastring{#1}, syll.items)},
  name .default:n = nil,
  hours .code:n = \luadirect{syll.item:setValue('hours', \luastring{#1})},
  hours .default:n = nil,
  h .code:n = \luadirect{syll.item:setValue('hours', \luastring{#1})},
  h .default:n = nil,
  topics .code:n = \luadirect{syll.item:setValue('topics', \luastring{#1})},
  topics .default:n = {},
  testing .code:n = \luadirect{syll.item:setValue('testing', \luastring{#1})},
  testing .default:n = {},
  totalnames .code:n = \luadirect{syll.item:setTotalNames({#1})},
  totalnames .default:n = {}
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
  \directlua{syll.item:startReading()}
}
{
  \directlua{syll.item:stopReading()}
  \directlua{
    syll.content[syll.items.type]=syll.items}
  % TODO: DUMP?
}

\NewDocumentEnvironment{topics}{O{}}
{
  \begin{syll@items}[totalnames={'lec','lab','sem','per'},type=topic,itemname={Тема},#1]
    \begin{rdfctx}{\rdfsetctx{list}{syll wpdd:itemList !wpdd:TopicList !wpdd:ItemList \luadirect{syll.Item:sprintRDFType()}}}
}
{
  \luadirect{syll.items:topicValidation()}
  % \luadirect{syll.saveState('\jobname' .. '.json')}
  \luadirect{syll.items:generateContentByTopic()}
    \end{rdfctx}
  \end{syll@items}
}

\NewDocumentEnvironment{topic}{O{}m}
{
  \begin{syll@item}[#1]{#2}
  \paragraph{\itemname\ \rdf{item dcterms:identifier}{\protect\theitem}.~\rdf{item rdfs:label}{#2}}\par
  \begin{rdfctx}{\rdfsetctx{item}{list ^schema:member !wpdd:ListItem !wpdd:Topic}}
}
{
  \end{rdfctx}
  \end{syll@item}
}


% \def\workname{Лабораторная работа}
\def\workheaderstyle{\normalfont\em}
\def\worktitlestyle{\normalfont}

\NewDocumentEnvironment{rdfenv}{O{}m}{}{}

\NewDocumentEnvironment{works}{O{}}
{
  \def\itemname{Работа студента}
  \begin{syll@items}[#1]
  % \luadirect{
  %   syll.items:sprintItemName()
  % }
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
  \begin{syll@item}[#1]{#2}
  \begin{rdfenv}{list ^schema:member !wpdd:ListItem !wpdd:Example \luadirect{self.item:sprintRDFTypes()} }
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

\ExplSyntaxOn

\AtBeginDocument{
  %\@input{\jobname.syll}
  \luadirect{syll.prev = syll.tbl.load('\jobname-content.lua')}
}

\AtEndDocument{
  \luadirect{syll.tbl.save(syll.content, '\jobname-content.lua')}
}

\def\syll@rerun{\par{\color{red}Требуется повторный запуск \LuaLaTeX}}

\NewDocumentCommand{\contentbytopic}{}{%
  \noindent{\footnotesize{}\luadirect{syll.generateContentByTopic()}}
}


\NewDocumentEnvironment{labworks}{O{}}
{
\syl@labwork@section
\begin{works}[totalnames={'hours'},type=labwork,itemname={Лабораторная работа},rdftype={LaboratoryWork},#1]}
{\end{works}}

\NewDocumentEnvironment{personalworks}{O{}}
{\begin{works}[totalnames={'hours'},type=personalwork,itemname={Самостоятельная работа},rdftype={PersonalWork},#1]}
{\end{works}}

\NewDocumentEnvironment{seminars}{O{}}
{\begin{works}[totalnames={'hours'},type=seminar,itemname={Семинар},rdftype={Seminar},#1]}
{\end{works}}

\NewDocumentEnvironment{practicalworks}{O{}}
{\begin{works}[totalnames={'hours'},type=practicalwork,itemname={Практическая работа},rdftype={PracticalWork},#1]}
{\end{works}}

\NewDocumentEnvironment{disciplines}{O{}}{
  \syl@disc@required@text
  \begin{enumerate}
  }{
    \end{enumerate}
}

\NewDocumentEnvironment{infosupport}{}
{
  \syl@infosupport@section
  \begin{syll@items}[type=infosupport]
}
{
  \end{syll@items}
}

\NewDocumentEnvironment{techsupport}{}
{
  \syl@techsupport@section
  \begin{syll@items}[type=techsupport]
}
{
  \end{syll@items}
}

\NewDocumentEnvironment{referencelist}{om}
{
  \noindent \IfNoValueTF{#1}{}{#1)\;}#2:\par
  \begin{syll@item@base}[]{#2}
  \begin{enumerate}
}
{
  \end{enumerate}
  \end{syll@item@base}
}

\NewDocumentEnvironment{warelist}{m}
{
  \syl@warelist@section{#1}
  \begin{syll@item@base}[]{#1}
    \begin{enumerate}
}
{
  \end{enumerate}
  \end{syll@item@base}
}


\ExplSyntaxOn

\NewDocumentCommand{\syllayout}{O{}m}{\gdef\syl@layout@id{#2}\input{\syl@layout@id-layout.tex}}

\NewDocumentEnvironment{cwtitle}{}{
  \begin{titlepage}
}
{ \syl@make@title
\end{titlepage}
\newpage
\tableofcontents
\newpage
}

\def\syl@comp@list@item#1{\@item[]\unskip #1\ -- }
\def\syl@bold@list@item#1{\@item[]\unskip {\bfseries #1} }
\def\syl@paragraph@list@item#1{\@item[]\unskip\hspace{\parindent}{\bfseries #1} }
\def\syl@trivial@list@item#1{\@item[]\unskip #1 }

\NewDocumentEnvironment{syl@list}{}{\list{}{
  \leftmargin\z@}
  \let\item\syl@bold@list@item
}{\endlist}

\NewDocumentEnvironment{competencelist}{}{
  \syl@competencelist@section
  \syl@competence@list@paragraph
  \begin{syl@list}
  \let\item\syl@comp@list@item
}
{
  \end{syl@list}
}

\NewDocumentEnvironment{abilities}{}{
  \syl@abilities@paragraph
  \begin{syl@list}
  \let\item\syl@paragraph@list@item
}{\end{syl@list}}

\NewDocumentEnvironment{aims}{}{
  \syl@aims@section
  \begin{syl@list}
  \let\item\syl@paragraph@list@item
}{\end{syl@list}}

\NewDocumentEnvironment{content}{}{
\syll@content@section
}{}


\ExplSyntaxOff

\newcommand\chair[2]{%
\gdef\syl@base@chair@name{#1}%
\gdef\syl@base@chair@abbrev{#1}%
}
\newcommand\institute[5]{%
\gdef\syl@institute@name{#1}%
\gdef\syl@institute@abbrev{#2}%
\gdef\syl@institute@head@position{#3}%
\gdef\syl@institute@head@name{#4}%
\gdef\syl@institute@city{#5}%
}
\newcommand\university[2]{%
\gdef\syl@university@preamble{#1}%
\gdef\syl@university@abbrev{#2}%
}
\newcommand\discipline[2]{%
\gdef\syl@disc@name{#1}%
\gdef\syl@disc@code{#2}%
}
\newcommand\specialty[2]{%
\gdef\syl@spec@name{#1}%
\gdef\syl@spec@code{#2}%
}
\newcommand\profile[1]{%
\gdef\syl@profile@name{#1}%
}
\newcommand{\masterdegree}{\gdef\syl@degree{Магистр}}
\newcommand{\bachelordegree}{\gdef\syl@degree{Бакалавр}}
\newcommand{\mural}{\gdef\syl@mural{Очная}} % форма обучения
\newcommand{\extramural}{\gdef\syl@mural{Заочная}} % форма обучения
\renewcommand{\year}[1]{\gdef\syl@cirr@year{#1}}
\renewcommand{\author}[1]{\gdef\syl@cirr@author{#1}}
\author{Иванов~И.И., к.т.н., доцент... (НАДО ЗАПОЛНИТЬ)}
\institute{НЕ УКАЗАН ИНСТИТУТ ИЛИ ФАКУЛЬТЕТ}{АББР}{Директор}{И.И.~Иванов}{ГОРОД N}
\chair{НЕ УКАЗАНА КАФЕДРА}{КАФ}
\newcommand{\personalworktechniquesubsection}{\syl@personalworktechniquesubsection@content}
