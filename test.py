import json
import re
from pprint import pprint

JSON = r"""{"buffer":[
"    \\item Леоненков А. Самоучитель UML 2 [текст] / А. Леоненков, 2010. -- 576 с. Неог. \\label{b1}",
"    \\item Буч Г. Язык UML. Руководство пользователя [текст], 2008. -- 496 с. Неог. \\label{b2}",
"    \\item Розенберг Д. Применение объектного моделирования с использованием UML и анализ прецедентов [текст], 2007. -- 160 с. Неог. \\label{b3}",
"    \\item Антониоу Г. Семантический веб [текст], 2016. -- 240 с. Неог. \\label{b4}",
"    \\item Цуканова Н. И. Теория и практика логического программирования на языке Visual Prolog 7. Учебное пособие для вузов [текст] / Н. И. Цуканова, Т. А. Дмитриева, 2013. -- 232 с. Неог. \\label{b5}",
"    \\item Марков В.Н. Современное логическое программирование на языке Visual Prolog 7.5 [текст] / В.Н. Марков, 2016. -- 544 с. Неог. \\label{b6}",
"    \\end{referencelist}",
""]}"""

WORDARG = r"\{[a-zA-Z0-9]+\}"
ITEM_RE = re.compile(r"\\.*?item\s*")
END_RE = re.compile(r"\s*\\end"+WORDARG)
LABEL_RE = re.compile(r"\s*\\label"+WORDARG)


def refsinjson(JSON):
    """Assume it contains list of references as text.
    Each reference started with \item or \bibitem, i.e.
    a regexp "\\.*?item", "{}" are removed.
    Extract author(s) list,
    possibly empty one, name and year of the publication"""

    text = JSON['buffer']  # List of strings.
    text = " ".join(text) if type(text) == list else text
    text = ' '.join(
        text.split())  # Replace all whitespace with just one whitespace
    text = END_RE.sub('', text)
    text = LABEL_RE.sub('', text)
    refs = ITEM_RE.split(text)
    refs = [r for r in refs if r]
    pprint(refs)

    authors = []
    name = ""
    year = 2020
    return authors, name, year


buf = json.loads(JSON)


def checklit(luabuf):
    bl = luabuf["buffer"]
    text = " ".join(bl)
    words = text.split()
    print(words)
    text = " ".join(words)
    print(text)
    text, typ = text.split(r"\end")
    items = text.split(r"\item")
    items = [i.strip() for i in items]
    items = [i for i in items if i]
    print("\n".join(items))


refsinjson(buf)
