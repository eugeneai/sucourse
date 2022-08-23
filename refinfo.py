import json
import re
from pprint import pprint
import pymorphy2
import ucto
from queryref import query
from storage import storeref

uctoconfig = "tokconfig-rus"
UCTOTOCKENIZER = ucto.Tokenizer(uctoconfig)

MORPH = pymorphy2.MorphAnalyzer()
JSON = r"""{"buffer":[
    "    \\item Ландау Л. Д. Теоретическая физика [Текст] : учеб. пособие для студ. физ. спец. ун-тов : в 10 т. / Л. Д. Ландау, Е. М. Лифшиц. - 8-е изд., стер. - М. : Физматлит. - 22 см. Т. 2 : Теория поля / ред. Л. П. Питаевский. -- 2012. -- 533 с.",
    "    \\item Леоненков А. Самоучитель UML 2 [текст] / А. Леоненков, 2010. -- 576 с. Неог. \\label{b1}",
    "    \\item Буч Г. Язык UML. Руководство пользователя [текст], 2008. -- 496 с. Неог. \\label{b2}",
    "    \\item Розенберг Д. Применение объектного моделирования с использованием UML и анализ прецедентов [текст], 2007. -- 160 с. Неог. \\label{b3}",
    "    \\item Антониоу Г. Семантический веб [текст], 2016. -- 240 с. Неог. \\label{b4}",
    "    \\item Цуканова Н. И. Теория и практика логического программирования на языке Visual Prolog 7. Учебное пособие для вузов [текст] / Н. И. Цуканова, Т. А. Дмитриева, 2013. -- 232 с. Неог. \\label{b5}",
    "    \\item Марков В.Н. Современное логическое программирование на языке Visual Prolog 7.5 [текст] / В.Н. Марков, 2016. -- 544 с. Неог. \\label{b6}",
    "    \\end{referencelist}",
    ""]}"""

JSON = r"""{"buffer":[
    "    \\item Ландау Л. Д. Теоретическая физика [Текст] : учеб. пособие для студ. физ. спец. ун-тов : в 10 т. / Л. Д. Ландау, Е. М. Лифшиц. - 8-е изд., стер. - М. : Физматлит. - 22 см. Т. 2 : Теория поля / ред. Л. П. Питаевский. -- 2012. -- 533 с.",
    "    \\end{referencelist}",
    ""]}"""

WORDARG = r"\{[a-zA-Z0-9]+\}"
ITEM_RE = re.compile(r"\\.*?item\s*")
END_RE = re.compile(r"\s*\\end" + WORDARG)
LABEL_RE = re.compile(r"\s*\\label" + WORDARG)
DOC_TYPE_RE = re.compile(r"\[.*?\]")
EX_WORDS_RE = re.compile(r"([Нн]еог|экз)[а-яА-Я.]*")
YEAR_RE = re.compile("^[1-2][0-9]{3}$")
VALUABLE_POS = {
    'NOUN', 'ADJF', 'ADJS', 'COMP', 'VERB', 'INFN', 'PRTF', 'PRTS', 'GRND',
    'ADVB', 'PRED', 'LATN'
}
BAD_POS = {''}

# rc = r.post("http://ellibnb.library.isu.ru/cgi-bin/irbis64r_15/cgiirbis_64.htm", data={"X_S21STR":"ЧЕРКАШИН ПОЛИСИСТЕМНОЕ МОДЕЛИРОВАНИЕ", "C21COM":"S", "I21DBN":"IRCAT"})


def removeother(words):
    lwords = [w.lower().strip() for w in words]
    filtered = [w for w, l in zip(words, lwords)]
    filtered = list(dict.fromkeys(filtered))  # remove duplicates
    return filtered


def getyears(words):
    return [w for w in words if YEAR_RE.match(w)]


def canonize(ref, pos):

    def _key(el):
        # t = el[-1]
        t = el
        if t.grammemes & {'Surn', 'Geox'}:
            return 0
        else:
            return 1

    UCTOTOCKENIZER.process(ref)
    words = [str(t) for t in UCTOTOCKENIZER]  # Better tokenizer
    tagsmorphy = [(w, MORPH.parse(w)[0].tag) for w in words]
    a, b = [(w,t) for w, t in tagsmorphy if _key(t) == 0], \
        [(w,t) for w, t in tagsmorphy if _key(t) == 1]
    tagssorted = a + b
    filtered = [(w, t) for w, t in tagssorted if t.POS in pos and len(w) > 2]
    # pprint(filtered)
    fwords = [w for w, _ in filtered]
    filtered = removeother(fwords)
    years = getyears(words)
    filtered.extend(years)
    return filtered, words, tagsmorphy


def reflisrecords(ref, pos=VALUABLE_POS, npos=BAD_POS, number=20):
    filtered, words, tagged = canonize(ref, pos=pos)
    for rec in query(filtered, number=number):
        del rec["__RAW__"]
        del rec['__PARTS__']
        # print(rec["count"])
        yield rec


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
    text = DOC_TYPE_RE.sub('', text)
    text = END_RE.sub('', text)
    text = LABEL_RE.sub('', text)
    text = EX_WORDS_RE.sub('', text)
    refs = ITEM_RE.split(text)
    refs = [r for r in refs if r]
    for r in refs:
        yield list(reflisrecords(r))  # yield all found in a LIS records
                                      # processed as list


def refauthor(ref, connector='~'):
    fn, name = ref.get('author', '')
    np = name.split()
    np = ['{}.'.format(n[0]) for n in np] + [fn]
    return '~'.join(np)


def reflistwithcounts(JSON):
    for dts in refsinjson(buf):
        # choose one with the greatest number of instances
        c = 0
        ref = None
        for dt in dts:
            # print("-------------------")
            storeref(dt)
            c1 = dt['count']
            if c1 > c: # prefer one with greatest count
                ref = dt
                c = c1
            elif c1 == c:
                if int(dt['year']) > int(ref['year']):  # prefer new one
                    ref = dt

        dt = ref
        s = "{}~--~{}~экз.".format(dt['issue'], dt['count'])
        author = refauthor(dt)
        if author:
            s = author + '.~' + s
        yield s, dt


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


if __name__ == "__main__":
    buf = json.loads(JSON)
    for ref, dt in reflistwithcounts(JSON):
        print(r'\item', ref, r'\label{id%s}' % dt['ref_id'])
