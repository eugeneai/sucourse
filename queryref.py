import requests as rq
from lxml.html import etree, parse, tostring, fromstring
import os.path, os
import re

URL = "http://ellibnb.library.isu.ru/cgi-bin/irbis64r_15/cgiirbis_64.htm"

TEST_STRING = "Леоненков Александр Васильевич Объектно-ориентированный анализ и проектирование с использованием UML и IBM Rational Rose"

ISBNS_RE = re.compile(r"[0-9-xхXХ\*]{9,}")
SM_RE = re.compile(r"-\s*[0-9]{1,2}\s*см.?\s*")

# a = "ISBN  5020152781, 5020152781 : 40.00 р.   На обл.авт.не указаны.-Предм.указ.:с.492-493.-На корешке "
# print(ISBNS_RE.findall(a))
# quit()


def query(terms, number=20):
    data = {
        "X_S21P03":
        "K=",  # Prefix for search terms, equals to the view dictionary
        "SearchIn": "",
        "I21DBN": "IRCAT",  # INI file section # IRCAT_PRINT
        "P21DBN": "IRCAT",  # Name of DB
        "LNG": "",
        "X_S21STR": " ".join(terms),  # Text to search (full text, stemmed)
        "X_S21P01":
        "4",  # Term extraction from (a) text 0 - Whole text is the term,
        # 2 - Term is the first word of the text till a space
        # 3 - similar the 3 but stemmed
        # 4 - According to the active parameter CHECKNAME
        # S21P02 Wether to use the right cutting of a term (0 - no, 1 - yes)
        # ...P03   "A=" - Author ? M= , U= UDC, S= - rubrics, K= - keyword
        # ...P04 Search term qualifier
        "X_S21LOG":
        "1",  # Logical connection between terms of a similar kind (0 - OR, 1 - AND, 2 - whole phrase, 3 - NEG)
        # "S21COLORTERMS": "1",
        "S21COLORTERMS": "0",  # Wether to highlite the term queried
        "S21STN": "1",  # Number of the first document in the response.
        "S21CNR": str(number),  # Number of records on the page
        "S21REF": "10",
        "S21ALL": "",  # Query in form of Irbis language <.>T=....????<.>
        "FT_REQUEST": "",
        "FT_PREFIX": "",
        "C21COM":
        "S",  # Command, F - Set of frames (e.g. printing), S - Search, T - Show terms of a dictionary, Z - Request?, R - Record update
        "C21COM1": "Поиск",
        # "Z21MFN":"247539",  # Record number ?
        # "S21FMT":"fullw_print"
        # Format of the output frus zakaz referings_img
        # Format file name
        # MFul (часть шпблона),
        # fullw (часть шаблона?),
        # briefHTML_ft (Общие цифры),
        # fullwebr (карточка для показа в веб),
        # WEB_URUB0_WN (Показывает рубрики),
        # infow_wh (полный, форма, поле: значение),
        # briefwebr (информационный, Только осноная часть как ссылка на литру),
        # RQST_WEB (запрос через WEB?)
        # v1009
        "S21FMT": "fullwebr",
        # "EXP21FMT": "TXT",
        # "EXP21CODE": "UTF-8"
    }

    # print(a.decode("utf8"))
    filename = "post-{}.html".format('-'.join(terms)[:20])  # a cache file
    if not os.path.exists(filename):
        rc = rq.post(URL, data=data)
        f = open(filename, "w")
        f.write(rc.text)
        f.close()
    with open(filename, "r") as f:
        text = f.read()
    tree = fromstring(text)
    trs = tree.xpath(
        '''//form[@name="SEARCH_FORM"]/table[@class="advanced"]/tr''')
    trs = trs[2:-1]
    for row in trs:
        yield proctablerow(row)


def location(s):
    # s = s.strip()
    # where, number = s.rsplit("(", 1)
    # number.strip(")")
    return s


def exemplars(s):
    """Process the string like:
    130 Инв. №:  физмат 21361(10 экз.), физмат 21361(120 экз.)    Свободны:  физмат (130)
    """
    ex = {}
    s = recordsplit(s, "Свободны:", ex, "in_stock", location)
    number, rest = s.split("Инв.")
    return int(number.strip())


def proctablerow(row):
    pcol, refcol = row[0], row[1]
    ref_id = pcol.xpath(".//a/@href")[0].split("Z21MFN=")[-1]
    rec = {}
    rec["ref_id"] = ref_id
    rec["__RAW__"] = refcol
    # print(etree.tostring(refcol, pretty_print=True, encoding=str))
    rawstr = ' '.join(refcol.itertext()).strip().rstrip("Найти похожие")
    parts = rawstr.split("\xa0\xa0\xa0")
    parts = [p.strip() for p in parts]
    rec["__STR__"] = rawstr
    parts = parts[:3] + [' '.join(parts[3:])]
    rec["__PARTS__"] = parts
    udcmain, bibmark, author, record = parts
    rec["udcmain"] = udcmain
    rec["bibmark"] = bibmark
    rec["author"] = [w.strip() for w in author.split(',')]
    rec["recordtext"] = record
    # Splitting the fields of the record from the end and add a field to rec
    record = recordsplit(record, "Учебная литература:", rec, "courses")
    record = recordsplit(record, "Экземпляры всего:", rec, "count", exemplars)
    record = recordsplit(record, "Доп.точки доступа:", rec, "auxaccess")

    def _split(x):
        return [kw.strip() for kw in x.split("--")]

    def _ssplit(x):
        return [kw.strip() for kw in x.split()]

    def _isbn(x):
        return ISBNS_RE.findall(x)

    record = recordsplit(record, "Кл.слова (ненормированные):", rec,
                         "keywords", _split)
    record = recordsplit(record, "Кл.слова:", rec, "keywords", _split)
    record = recordsplit(record, "Рубрики:", rec, "rubrics", _split)
    rec["issueraw"] = record
    record = recordsplit(record, "УДК", rec, "UDC", _ssplit)
    record = recordsplit(record, "ISBN", rec, "ISBN",
                         _isbn)  # TODO: process all ISBNs
    record = record.rstrip("-").rstrip()
    record = SM_RE.sub("- ", record, 1)
    record = ' '.join(record.split())
    rec["issue"] = record
    return rec


def recordsplit(record, textfield, rec, name, proc=None):
    parts = [p.strip() for p in record.rsplit(textfield, maxsplit=1)]
    if len(parts) == 1:
        return record
    a, b = parts
    if callable(proc):
        b = proc(b)
    rec[name] = b
    return a
