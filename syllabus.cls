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

% \NewDocumentCommand{\thetopic}{}{\arabic{syllabus@topic}}
\def\thetopic{\arabic{syllabus@topic}}
\NewDocumentCommand{\TopicControl}{m}{
  \luadirect{syll.Topics:setControl{control="#1"}}
}
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

\NewDocumentEnvironment{topics}{O{}}
{
  \setcounter{syllabus@topic}{0}
  \keys_set:nn { syllabus/topics } { #1 }
  \begin{rdfctx}{\rdfsetctx{list}{syll wpdd:itemList !wpdd:TopicList !wpdd:ItemList}}
}
{
  \luadirect{syll.Topics:validation()}
  \luadirect{syll.saveState('\jobname' .. '.json')}
\end{rdfctx}
}

\keys_define:nn { syllabus/topics }
{
  lec .code:n = \luadirect{syll.Topics:setControl({lec=#1})},
  lec .default:n = nil,
  lab .code:n = \luadirect{syll.Topics:setControl({lab=#1})},
  lab .default:n = nil,
  sem .code:n = \luadirect{syll.Topics:setControl({sem=#1})},
  sem .default:n = nil,
  per .code:n = \luadirect{syll.Topics:setControl({per=#1})},
  per .default:n = nil,
  control .code:n = \luadirect{syll.Topics.control=\luastring{#1}},
  control .default:n = nil,
  term .code:n = \luadirect{syll.Topics.term=#1},
  term .default:n = nil,
}

\def\topicname{Тема} % Раздел

\NewDocumentEnvironment{topic}{O{}mb}
{
  \refstepcounter{syllabus@topic}
  \begin{rdfctx}{\rdfsetctx{item}{list ^schema:member !wpdd:ListItem !wpdd:Topic  \end{rdfctx}}}
  {\bfseries \topicname\ \rdf{item dcterms:identifier}{\protect\thetopic}.~\rdf{item rdfs:label}{#2}}\par
  \let\oldtheenumi=\theenumi
  \RenewDocumentCommand{\theenumi}{}{\thetopic.\arabic{enumi}}
  \directlua{
    syll.topic = syll.Topic:new{index=\thetopic, title='#2'}
  }
  \keys_set:nn { syllabus/topic } { #1 }
  \directlua{
    syll.Topics:addTopic(syll.topic)
  }
  #3
}
{
  \let\theenumi=\oldtheenumi
  \let\oldtheenumi=\relax
  % \luadirect{
  %   syll.pt(syll.topic, 'TOPIC:')
  %   syll.topic:sprintTitle('emph')
  % }
  \end{rdfctx}
}

\keys_define:nn { syllabus/topic }
{
  lec .code:n = \luadirect{syll.topic.lec=#1},
  lec .default:n = nil,
  lab .code:n = \luadirect{syll.topic.lab=#1},
  lab .default:n = nil,
  sem .code:n = \luadirect{syll.topic.sem=#1},
  sem .default:n = nil,
  per .code:n = \luadirect{syll.topic.per=#1},
  per .default:n = nil,
  label .code:n = \luadirect{syll.topic.label=\luastring{#1}},
  label .default:n = nil,
  term .code:n = \luadirect{local term=#1; syll.topic.term=term or syll.Topics.term},
  term .default:n = nil
}

% \def\workname{Лабораторная работа}
\def\workheaderstyle{\normalfont\em}
\def\worktitlestyle{\normalfont}
\newcounter{syllabus@work}
\def\thework{\arabic{syllabus@work}}

\NewDocumentEnvironment{rdfenv}{O{}m}
{

}
{

}

\NewDocumentEnvironment{works}{O{}}
{
  \setcounter{syllabus@work}{0}
  \def\workname{Работа студента}
  \luadirect{
    syll.Works:clear()
  }
  \keys_set:nn { syllabus/works } { #1 }
  \luadirect{
    syll.Works:sprintWorkName()
  }
  \begin{rdfctx}{\rdfsetctx{list}{syll wpdd:itemList !wpdd:ExampleList !wpdd:CurrentAttestation !wpdd:ItemList}}
  \def\syllabus@worktype{wpdd:LaboratoryWork}
}
{
  \luadirect{
    syll.Works:validation()
  }
\end{rdfctx}
}

\keys_define:nn { syllabus/works }
{
  comp .code:n = \luadirect{syll.Works.comp=\luastring{#1}},
  comp .default:n = nil,
  type .code:n = \luadirect{syll.Works:setType('#1')},
  type .default:n = lab,
  name .code:n = \luadirect{local name='#1'; syll.Works:setName(name) },
  name .default:n = nil,
  term .code:n = \luadirect{local term=#1; syll.Works.term = term or syll.Topics.term},
  term .default:n = nil
}

\NewDocumentEnvironment{work}{O{}m}
{
  \refstepcounter{syllabus@work}
  \luadirect{
    syll.work = syll.Work:new{index=\thework, title=[[#2]]}
  }
  \keys_set:nn { syllabus/work } { #1 }
  \luadirect{
    syll.Works:addWork(syll.work)
  }
  \begin{rdfenv}{list ^schema:member !wpdd:ListItem !wpdd:Example \luadirect{syll.Works:sprintRDFType()}}
  \paragraph{{\workheaderstyle \workname\ \thework.}~{\worktitlestyle #2}}
}
{
\end{rdfenv}\par\vspace{1em}
}

\keys_define:nn { syllabus/work }
{
  comp .code:n = \luadirect{local comp=[[#1]]; syll.work:setComp(comp)},
  comp .default:n = nil,
  hours .code:n = \luadirect{syll.work.hours=#1},
  hours .default:n = nil,
  topics .code:n = \luadirect{local topics=[[1]]; syll.work:setTopics(topics)},
  topics .default:n = {},
  label .code:n = \luadirect{syll.work.label=\luastring{#1}},
  label .default:n = nil,
  term .code:n = \luadirect{local term=#1; syll.work.term=term or syll.Works.term or syll.Topics.term},
  term .default:n = nil
}

\AtEndPreamble{
%
\rdf{%
  \rdfsetctx{syll}{wpdb:_}%
%  \rdfsetctx{common}{wpdb:_}%
}{}
}

\ExplSyntaxOff
