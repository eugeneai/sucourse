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

\newcounter{syllabus@topic}

\ProvideDocumentCommand{\thetopic}{}{\arabic{syllabus@topic}}

\NewDocumentEnvironment{topics}{O{}}
{
\setcounter{syllabus@topic}{0}
\begin{rdfctx}{\rdfsetctx{list}{syll wpdd:itemList !wpdd:TopicList !wpdd:ItemList}}
}
{
\end{rdfctx}
}

\NewDocumentCommand{\topicname}{}{Тема} % Раздел

\NewDocumentEnvironment{topic}{O{}m}
{
  \refstepcounter{syllabus@topic}
  \begin{rdfctx}{\rdfsetctx{item}{list ^schema:member !wpdd:ListItem !wpdd:Topic  \end{rdfctx}}}
  {\bfseries \topicname\ \rdf{item dcterms:identifier}{\protect\thetopic}.~\rdf{item rdfs:label}{#2}}\par
  \let\oldtheenumi=\theenumi
  \RenewDocumentCommand{\theenumi}{}{\thetopic.\arabic{enumi}}
}
{
  \let\theenumi=\oldtheenumi
  \let\oldtheenumi=\relax
  \end{rdfctx}
}


\NewDocumentCommand\syllabuscontentbytopics{}{SYLLABUS HERE\par}



\AtEndPreamble{
%
\rdf{%
  \rdfsetctx{syll}{wpdb:_}%
%  \rdfsetctx{common}{wpdb:_}%
}{}
}

\ExplSyntaxOff
