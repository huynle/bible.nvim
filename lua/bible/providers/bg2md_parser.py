import re
import subprocess
import hashlib

regex_parse = {
        "chapter": "asdf",
        # this is the best one so far, capturing between two verses, or an end
        # line
        "verse": r"(?<=(\d\s))(.*?)(?=(\d{1,3}\s|\\n\\n))",
        "footnote": "",
        }


def bg2md_call(args, use_old=False):

    hash_object = hashlib.md5(args.encode()).hexdigest()

    try:
        with open(hash_object, "rb") as f:
            return f.read().decode("utf-8")
    except IOError:
        print('Cant find previous result, gonna request bg2md')

    byte_ret = subprocess.Popen("bg2md " + args, shell=True, stdout=subprocess.PIPE).stdout.read()
    with open(hash_object, "wb") as binary_file:
        # Write bytes to file
        binary_file.write(byte_ret)
    return byte_ret.decode("utf-8")

def break_section(value):
    # split up into section of verses, footnotes, crossrefs
    ret = re.split(r"\n\n", value)

    chapters = re.split(r"## ", ret[0])

    for chap in chapters:
        print("CHAPTER ===== ")
        verses = re.findall(regex_parse["verse"], chap)
        print(verses)

    # print(ret)

if __name__ == "__main__":
    result = bg2md_call("--copyright --version NABRE John3:16-John4:15", use_old=True)

    break_section(result)
    # print(result)
