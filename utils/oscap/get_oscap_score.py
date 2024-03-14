#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import argparse 


def main():
    parser = argparse.ArgumentParser(
        prog="get_oscap_score",  
        description='Get oscap score from results.xml created after running "oscap xcccdef eval"',
        allow_abbrev=True,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("-f", "--file", dest="result_xml", help="oscap eval xml result\n", required=True)

    args = parser.parse_args()

    tree = ET.parse(args.result_xml)
    root = tree.getroot()
    score = root[-1][-1].text
    print (f'CIS SCORE: {score}')

if __name__ == '__main__':
    main()

