#!/usr/bin/env python

import sys

try:
    import requests
except ImportError:
    print('Could not import REQUESTS library')
    print('pip install requests')
    sys.exit(1)


f0 = {
        '30x6': ('30f4', '30k4', '30f6', '30k6'),
        '30x8': '30c8',
        '31x6': ('31f4', '31f6'),
        '38xx': ('38f6', '38k6'),
        '42x6': ('42f4', '42f6'),
        '48xx': ('48f6', '48f6'),
        '51x8': ('51f4', '51f6', '51k4', '51k6', '51c8'),
        '58xx': '58c8',
        '70x6': ('70f4', '70f6', '70k4', '70k6'),
        '70xb': ('70c8', '70cb'),
        '71xb': ('71c8', '71cb'),
        '72xb': ('72c8', '72cb'),
        '78xx': '78cb',
        '30xc': ('30rc', '30vc'),
        '91xc': ('91cb', '91vc'),
        '98xx': '98vc'
     }

f1 = {
       '00xb': ('00c4', '00r4', '00c6', '00r6', '00c8', '00r8', '00v8', '00cb', '00r8', '00vb'),
       '00xe': ('00rc', '00vc', '00zc', '00rd', '00vd', '00zd', '00re', '00ve' '00ze'),
       '01x6': ('01c4', '01r4', '01t4', '01c6', '01r6', '01t6'),
       '01xb': ('01c8', '01r8', '01t8', '01v8', '01cb', '01rb', '01tb', '01vb'),
       '01xe': ('01rc', '01vc', '01zc', '01rd', '01vd', '01zd', '01re', '01ve', '01ze'),
       '01xg': ('01rf', '01vf', '01zf', '01rg', '01vg', '01zg'),
       '02x6': ('02c4', '02r4', '02c6', '02r6'),
       '02xb': ('02c8', '02r8', '02cb', '02rb'),
       '03x6': ('03c4', '03r4', '03t4', '03c6', '03r6', '03t6'),
       '03xb': ('03c8', '03r8', '03t8', '03v8', '03cb', '03rb', '03tb', '03vb'),
       '03xe': ('03rc', '03vc', '03zc', '03rd', '03vd', '03zd', '03re', '03ve', '03ze'),
       '03xg': ('03rf', '03vf', '03zf', '03rg', '03vg', '03zg'),
       '05xc': ('05r8', '05v8', '05rb', '05vb', '05rc', '05vc'),
       '07xc': ('07rb', '07vb', '07rc', '07vc')
     }

f2 = {
       '05xx': ('05rg', '05vg', '05zg', '05rf', '05vf', '05zf', '05re', '05ve', '05ze', '05rc', '05vc',
                '05zc', '05rb', '05vb'),
       '15xx': ('15rg', '15vg', '15zg', '15re', '15ve', '15ze'),
       '07xx': ('07vg', '07zg', '07ig', '07vf', '07zf', '07if', '07ve', '07ze', '07ie', '07vc', '07zc', '07ic'),
       '17xx': ('17vg', '17zg', '17ig', '17ve', '17ze', '17ie')
     }

f3 = {
       '01x8': ('01k6', '01k8', '01c6', '01c8', '01r6', '01r8'),
       '02x8': ('02k6', '02k8', '02c6', '02c8', '02r6', '02r8'),
       '02xc': ('02cb', '02cc', '02rb', '02rc', '02vb', '02vc'),
       '02xe': ('02re', '02ve', '02ze', '02rd', '02vd', '02zd'),
       '03x8': ('03k6', '03k8', '03c6', '03c8', '03r6', '03r8'),
       '03xc': ('03cb', '03cc', '03rb', '03rc', '03vb', '03vc'),
       '03xe': ('03re', '03ve', '03ze', '03rd', '03vd', '03zd'),
       '73xc': ('73c8', '73cb', '73cc', '73r8', '73rb', '73rc', '73v8', '73vb', '73vc'),
       '34x8': ('34k4', '34k6', '34k8', '34c4', '34c6', '34c8', '34r4', '34r6', '34r8'),
       '18xx': ('18k8', '18c8'),
       '28xx': ('28c8', '28r8'),
       '58xx': ('58cc', '58rc', '58vc'),
       '78xx': ('78cc', '78rc', '78vc'),
       '98xx': '98ve'
     }

f4 = {
       '01xc': ('01cb',  '01cc',  '01rb',  '01rc', '01vb', '01vc'),
       '01xe': ('01cd',  '01rd',  '01vd',  '01ce', '01re', '01ve'),
       '05xx': ('05rg',  '05vg',  '05zg'),
       '07xx': ('07vg',  '07ve',  '07zg',  '07ze', '07ig', '07ie'),
       '10tx': ('10t8',  '10tb'),
       '10cx': ('10c8',  '10cb'),
       '10rx': ('10r8',  '10rb'),
       '11xe': ('11cc',  '11rc',  '11vc',  '11ce', '11re', '11ve'),
       '12cx': ('12ceu', '12cgu'),
       '12zx': ('12zet', '12zgt', '12zej', '12zgj'),
       '12vx': ('12vet', '12vgt', '12veh', '12vgh'),
       '12rx': ('12ret', '12rgt', '12rey', '12rgy'),
       '13xx': ('13ch',  '13mh',  '13rh',  '13vh', '13zh', '13cg', '13mg', '13rg', '13vg', '13zg'),
       '15xx': ('15rg',  '15vg',  '15zg'),
       '17xx': ('17vg',  '17ve',  '17zg',  '17ze', '17ig', '17ie'),
       '23xx': ('23ch',  '23rh',  '23vh',  '23zh'),
       '27xx': ('27vg',  '27vi',  '27zg',  '27zi', '27ig', '27ii'),
       '37xx': ('37vg',  '37vi',  '37zg',  '37zi', '37ig', '37ii'),
       '29xx': ('29vg',  '29vi',  '29zg',  '29zi', '29bg', '29bi', '29ng', '39ni', '29ig', '29ii'),
       '39xx': ('39vg',  '39vi',  '39zg',  '39zi', '39bg', '39bi', '39ng', '39ni', '39ig', '39ii'),
       '46xx': ('46mc',  '46me',  '46rc',  '46re', '46vc', '46ve', '46zc', '46ze'),
       '69xx': ('69ai',  '69ii',  '69bi',  '69ni', '69ag', '69ig', '69bg', '69ng', '69ae', '69ie', '69be', '69ne'),
       '79xx': ('79ai',  '79ii',  '79bi',  '79ni', '79ag', '79ig', '79bg', '79ng')
     }

f7 = {
       '45xx': ('45ve', '45vg', '45zg', '45ze', '45ie', '45ig'),
       '56xx': ('56vg', '56zg', '56zg', '56ig', '56bg', '56ng'),
       '46xx': ('46ve', '46vg', '46ze', '46zg', '46ie', '46ig', '46be', '46bg', '46ne', '46ng'),
       '65xx': ('65bi', '65bg', '65ni', '65ng', '65ii', '65ig', '65zi', '65zg', '65vi', '65vg'),
       '67xx': ('67bg', '67bi', '67ig', '67ii', '67ng', '67ni', '67vg', '67vi', '67zg', '67zi'),
       '69xx': ('69ag', '69ai', '69bg', '69bi', '69ig', '69ii', '69ng', '69ni', '68ai'),
       '22xx': ('22ie', '22ze', '22ve', '22re', '22ic', '22zc', '22vc', '22rc'),
       '32xx': ('32ie', '32ze', '32ve', '32re'),
       '77xx': ('77vi', '77zi', '77ii', '77bi', '77ni'),
       '79xx': ('79ii', '79bi', '79ni', '79ai', '78ai'),
       '33xx': ('33ie', '33ze', '33ve'),
       '30xx': ('30r8', '30v8', '30z8'),
       '23xx': ('23ie', '23ze', '23ve', '23ic', '23zc', '23vc'),
       '50xx': ('50v8', '50z8', '50n8')
     }

h7 = {
       '42xx': ('42vi', '42zi', '42ai', '42ii', '42bi', '42xi'),
       '43xx': ('43vi', '43zi', '43ai', '43ii', '43bi', '43xi'),
       '53xx': ('53vi', '53zi', '53ai', '53ii', '53bi', '53xi'),
       '47xx': ('47zi', '47ai', '47ii', '47bi', '47xi'),
       '57xx': ('57zi', '57ai', '57ii', '57bi', '57xi'),
       '45xx': ('45zi', '45ii', '45bi', '45xi'),
       '55xx': ('55zi', '55ii', '55bi', '55xi'),
       '23xx': ('23vg', '23ve', '23zg', '23ze'),
       '33xx': ('33vg', '33ve', '33zg', '33ze'),
       '30xx': ('30ab', '30vb', '30ib', '30zb'),
       '50xx': ('50vb', '50ib', '50xb'),
       'a3xx': ('a3ai', 'a3ii', 'a3ni', 'a3ri', 'a3vi', 'a3qi', 'a3zi'),
       'b3xx': ('b3ai', 'b3ii', 'b3ni', 'b3ri', 'b3vi', 'b3qi', 'b3zi'),
       '25xx': ('25ag', '25ig', '25rg', '25vg', '25zg', '25re', '25ve', '25ze', '25ae', '25ie'),
       '35xx': ('35ag', '35ig', '35rg', '35vg', '35zg', '35re', '35ve', '35ze', '35ae', '35ie'),
       'b0xx': ('b0ab', 'b0ib', 'b0rb', 'b0vb', 'b0zb')
     }

l0 = {
       '10x4': ('10k4', '10f4'),
       '10x6': '10c6',
       '10x8': ('10k8', '10r8'),
       '10xb': '10rb',
       '11xx': ('11d3', '11g4', '11e3', '11f3', '11k3', '11d4', '11g4', '11k4', '11e4', '11f4'),
       '21xx': ('21d4', '21f4', '21g4', '21k4'),
       '31xx': ('31c6', '31e6', '31f6', '31g6', '31k6'),
       '41xx': ('41c6', '41k6', '41g6', '41f6', '41e6'),
       '51xx': ('51k8', '51c6', '51c8', '51r6', '51r8', '51k6', '51t6', '51t8'),
       '52xx': ('52k6', '52k8', '52c6', '52c8', '52r6', '52r8', '52t6', '52t8'),
       '53xx': ('53c6', '53c8', '53r6', '53r8'),
       '62xx': '62k8',
       '63xx': ('63c8', '63r8'),
       '71xx': ('71v8', '71k8', '71vb', '71rb', '71cb', '71kb', '71vz', '71rz', '71cz', '71kz', '71c8'),
       '72xx': ('72v8', '72vb', '72rb', '72cb', '72vz', '72rz', '72cz', '72kb', '72kz'),
       '73xx': ('73v8', '73vb', '73rb', '73vz', '73rz', '73cb', '73cz'),
       '81xx': ('81cb', '81cz', '81kz'),
       '82xx': ('82kb', '82kz', '82cz'),
       '83xx': ('83v8', '83vb', '83rb', '83vz', '83rz', '83cb', '83cz')
     }

l1 = {
       '00xba': ('00c6-a', '00r8-a', '00rb-a'),
       '00xb':  ('00c6', '00r8', '00rb'),
       '00xc':  '00rc',
       '51xb':  ('51c6', '51r6', '51c8', '51r8', '51v8', '51cb', '51rb', '51vb'),
       '51xba': ('51c6-a', '51r6-a', '51c8-a', '51r8-a', '51v8-a', '51cb-a', '51rb-a', '51vb-a'),
       '51xc':  ('51cc', '51uc', '51rc', '51vc'),
       '51xca': ('51rc-a', '51vc-a', '51qc', '51zc'),
       '51xd':  ('51qd', '51rd', '51vd', '51zd'),
       '51xdx': '51vd-x',
       '51xe':  ('51qe', '51re', '51ve', '51ze'),
       '52xb':  ('52c6', '52r6', '52c8', '52r8', '52v8', '52cb', '52rb', '52vb'),
       '52xba': ('52c6-a', '52r6-a', '52c8-a', '52r8-a', '52v8-a', '52cb-a', '52rb-a', '52vb-a'),
       '52xc':  ('52cc', '52uc', '52rc', '52vc'),
       '52xca': ('52rc-a', '52vc-a', '52qc', '52zc'),
       '52xd':  ('52qd', '52rd', '52vd', '52zd'),
       '52xdx': '52vd-x',
       '52xe':  ('52qe', '52re', '52ve', '52ze'),
       '62xc':  '62rc',
       '62xca': ('62rc-a', '62vc-a', '62qc', '62zc'),
       '62xd':  ('62qd', '62rd', '62vd', '62zd'),
       '62xdx': '62vd-x',
       '62xe':  ('62re', '62ve', '62ze')
     }

mcu = {'f0': ('30x6', '30x8', '30xc', '31x6', '38xx', '42x6', '48xx', '51x8',
              '58xx', '70x6', '70xb', '71xb', '72xb', '78xx', '91xc', '98xx'),

       'f1': ('00xb', '00xe', '01x6', '01xb', '01xe', '01xg', '02x6', '02xb',
              '03x6', '03xb', '03xe', '03xg', '05xc', '07xc'),

       'f2': ('05xx', '07xx', '15xx', '17xx'),

       'f3': ('01x8', '02x8', '02xc', '02xe', '03x8', '03xc', '03xe', '18xx',
              '28xx', '34x8', '58xx', '73xc', '78xx', '98xx'),

       'f4': ('01xc', '01xe', '05xx', '07xx', '10cx', '10rx', '10tx', '11xe',
              '12cx', '12rx', '12vx', '12zx', '13xx', '15xx', '17xx', '23xx',
              '27xx', '29xx', '37xx', '39xx', '46xx', '69xx', '79xx'),

       'f7': ('22xx', '23xx', '30xx', '32xx', '33xx', '45xx', '46xx', '50xx',
              '56xx', '65xx', '67xx', '69xx', '77xx', '79xx'),

       'h7': ('23xx', '25xx', '30xx', '30xxq', '33xx', '35xx', '42xx', '43xx',
              '45xx', '47xx', '50xx', '53xx', '55xx', '57xx', 'a3xx', 'a3xxq',
              'b0xx', 'b0xxq', 'b3xx', 'b3xxq'),

       'l0': ('10x4', '10x6', '10x8', '10xb', '21xx', '31xx', '41xx', '51xx',
              '52xx', '53xx', '62xx', '63xx', '71xx', '72xx', '73xx', '81xx',
              '82xx', '83xx'),

       'l1': ('00xb', '00xba', '00xc', '51xb', '51xba', '51xc', '51xca', '51xd',
              '51xdx', '51xe', '52xb', '52xba', '52xc', '52xca', '52xd', '52xdx',
              '52xe', '62xc', '62xca', '62xd', '62xdx', '62xe'),

       'l4': ('12xx', '22xx', '31xx', '32xx', '33xx', '42xx', '43xx', '51xx',
              '52xx', '62xx', '71xx', '75xx', '76xx', '85xx', '86xx', '96xx',
              'a6xx', 'p5xx', 'q5xx', 'r5xx', 'r7xx', 'r9xx', 's5xx', 's7xx',
              's9xx'),

       'g0': ('30xx', '31xx', '41xx', '50xx', '51xx', '61xx', '70xx', '71xx',
              '81xx', 'b0xx', 'b1xx', 'c1xx'),

       'g4': ('31xx', '41xx', '71xx', '73xx', '74xx', '83xx', '84xx', '91xx', 'a1xx')
       }


def get_header_file_name(fmly, ndx):
    return f'stm32{fmly}{mcu[fmly][ndx]}.h'


def get_src_url(fmly, name):
    return 'https://raw.githubusercontent.com/STMicroelectronics/STM32Cube'\
        f'{fmly.upper()}/master/Drivers/CMSIS/Device/ST/STM32{fmly.upper()}xx/Include/stm32{fmly}{name}.h'


# def compose_cmsis_header_file_url(header_name):
#     return 'https://raw.githubusercontent.com/STMicroelectronics/STM32Cube'\
#         f'{header_name[5:7].upper()}/master/Drivers/CMSIS/Device/ST/STM32'\
#         f'{header_name[5:7].upper()}xx/Include/{header_name}'


def compose_cmsis_header_file_url(header_name):
    return 'https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_'\
           f'{header_name[5:7]}/master/Include/{header_name}'


def compose_cmsis_header_file_name(hdr_name):
    hn = hdr_name.lower()

    if hn.startswith('stm32'):
        hn = hn[5:]

    if hn[0] in '0123456789':
        hn = 'f' + hn

    res = hn[2:6]
    k1 = hn[0:2]

    if k1 == 'f0':
        a = f0
    elif k1 == 'f1':
        a = f1
    elif k1 == 'f2':
        a = f2
    elif k1 == 'f3':
        a = f3
    elif k1 == 'f4':
        a = f4
    elif k1 == 'f7':
        a = f7
    elif k1 == 'h7':
        a = h7
    elif k1 == 'l0':
        a = l0
    elif k1 == 'l1':
        a = l1
    elif k1 == 'l4':
        return "stm32l4" + hn[2:4] + 'xx.h'
    elif k1 == 'g0':
        return "stm32g0" + hn[2:4] + 'xx.h'
    elif k1 == 'g4':
        return "stm32g4" + hn[2:4] + 'xx.h'

    else:
        res = "stm32" + hn + ".h"
        return res

    for gx in a:
        if res in a[gx]:
            res = "stm32" + k1 + gx + ".h"
            return res

    return hdr_name


def read_cmsis_header_file(mcu_name):
    hdr_file_name = compose_cmsis_header_file_name(mcu_name)
    r = requests.get(compose_cmsis_header_file_url(hdr_file_name))
    return (r.text, hdr_file_name) if r.ok else ("", "")


# Press the green button in the gutter to run the script.
if __name__ == '__main__':

    import re

    # microcontroller_name = '107rc'
    # microcontroller_name = 'stm32l151c8'
    # microcontroller_name = 'stm32f765vg'
    microcontroller_name = 'h7a3zi'
    # microcontroller_name = '429ig'

    header_text = read_cmsis_header_file(microcontroller_name)

    m = re.findall(r'Peripheral_registers_structures(.*?)Peripheral_memory_map', header_text, re.MULTILINE | re.DOTALL)
    n = re.findall(r'(.*?)\s*}\s*(\w*?TypeDef);', m[0], re.MULTILINE | re.DOTALL)
    for x in n:
        # print((x[1] + ':').ljust(30), end='')
        p = re.findall(r'/\*\*[^*].*?@brief\s*(.*?)\s*\*/', x[0], re.MULTILINE | re.DOTALL)
        dev_desc = (x[1], p[0] if p else "")
        print(dev_desc)
        # if p:
        #     print(p[0])
        # else:
        #     print()
        continue

        q = re.findall(r'typedef\s+struct\s*{\s*(.*)', x[0], re.MULTILINE | re.DOTALL)
        if q:
            e = q[0].split('\n')
            for y in e:
                print('  ', y.strip())
            else:
                print()
