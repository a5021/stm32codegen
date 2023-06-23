#  #!/usr/bin/env python3

import re
import sys

try:
    from stm32cmsis import read_cmsis_header_file, compose_cmsis_header_file_name
except ImportError:
    print('Could not import STM32 CMSIS library')
    sys.exit(1)

max_field_len = [0, 0, 0]

# all definitions from header file in the following format:
#  'MACRO_NAME',      'VALUE',                'COMMENT',                  'EXTRA_VALUE'
# ['RCC_CR_HSERDY', '(1 << 17)', 'External High Speed clock ready flag',  '0x00020000']
macro_definition = []

# typedef list for all peripherals like 'TIM_TypeDef', 'USART_TypeDef' etc.
typedef_list = []

# complete list of all peripherals in the format of:
# 'HEX_ADDRESS',   'NAME',     'TYPEDEF',         'COMMENT'
# ['0x40000000',   'TIM2',   'TIM_TypeDef*',  'Timer peripheral']
peripheral_data = []

# peripheral register's dictionary: { "TypeDef" : [['REGISTER NAME', 'LENGTH', 'COMMENT' ],[...], ... }
# {'I2C_TypeDef': [['CR1', '4', ''], ['CR2', '4', ''], ['OAR1', '4', ''], ['OAR2', '4', ''], ['DR', '4', '']...]...}
#
register_dic = {}

uniq_type = set()
uniq_addr = set()

indent = 2 * ' '


init_macro_name = set()     # set of generated macro names

irq_list = []


class Bit:
    """Microcontroller's peripheral register bit class"""

    def __init__(self, bit):
        bl = len(bit)
        if bl > 0:
            self.mask1 = bit[0]
        else:
            self.mask1 = ''

        if bl > 1:
            self.mask2 = bit[1]
        else:
            self.mask2 = ''

        if bl > 2:
            self.descr = bit[2]
        else:
            self.descr = ''

        if bl > 3:
            self.value = bit[3]
        else:
            self.value = ''

    def set_value(self, value):
        self.value = value
        return self


class Register:
    """Microcontroller's peripheral register class"""

    def __init__(self, reg):
        self.address = reg[0]
        self.size = reg[1]
        self.description = reg[2]
        self.bit = reg[3]
        if len(reg) < 5:
            self.value = '0'
        else:
            self.value = reg[4]

    def set_data(self, reg_data):
        self.bit = reg_data
        return self

    def get_data(self):
        return self.bit

    def set_value(self, value):
        self.value = value
        return self


class Peripheral:
    """Microcontroller's peripheral class"""

    def __init__(self, periph):
        self.address = periph[0]
        self.typedef = periph[1]
        self.description = periph[2]
        self.register = periph[3]

    def set_data(self, reg_data):
        self.register = reg_data

    def get_data(self):
        return self.register


class Microcontroller:
    """Microcontroller class"""

    def __init__(self, uc_name, uc_descr, periph_list):
        self.name = uc_name
        self.description = uc_descr
        self.peripheral = periph_list

    def set_data(self, uc_data):
        self.name = uc_data[0]
        self.description = uc_data[1]
        self.peripheral = uc_data[2]

    def get_data(self):
        return [self.name, self.description, self.peripheral]


bits = []


def get_irq_list(src):
    m = re.findall(r'(\w*_IRQn).*=.*?([- ]\d+).*/\*(.*)\*/', src, re.MULTILINE)
    irq = []
    for xm in m:
        if len(xm) > 2:
            no = int(xm[1])
            irq_handler = xm[0].replace('_IRQn', '_IRQHandler')
            if no < 0:
                s01 = xm[0]
                s01 = s01.replace('NonMaskableInt', 'NMI')
                s01 = s01.replace('MemoryManagement', 'MemManage')
                s01 = s01.replace('SVCall', 'SVC')
                s01 = s01.replace('DebugMonitor', 'DebugMon')
                irq_handler = s01.replace('_IRQn', '_Handler')

            irq.append([xm[0], irq_handler, xm[1], xm[2].strip(' !<')])

    return irq


def wrap_string(text, line_length):
    """
    Wrap string to specified line length and return list of wrapped strings.

    Parameters:
        text (str): The text to wrap.
        line_length (int): The maximum line length.

    Returns:
        list: The wrapped text as a list of strings.
    """
    words = text.split()
    lines = []
    current_line = ""
    for word in words:
        if len(current_line) + len(word) <= line_length:
            current_line += word + " "
        else:
            lines.append(current_line.strip())
            current_line = word + " "
    lines.append(current_line.strip())
    return lines


def copyright_message(cname):

    h_indent = indent if (args.mix or args.direct) and not args.function else ''

    cmd_line = ' '.join(f'"{arg}"' if " " in arg else arg for arg in sys.argv[1:])

    s1 = f'  This code was generated for the {cname.strip(".h")} microcontroller by "stm32cgen" tool.'
    l1 = len(s1) + 2
    s0 = ''.ljust(l1, '*') + '\n'
    s2 = 'https://github.com/a5021/stm32codegen'.center(l1)

    s3 = 'Arguments used:'
    s4 = ''
    if len(cmd_line) > 58:
        for cln in wrap_string(cmd_line, l1 - 8):
            s4 += cln.center(l1) + '\n'
    else:
        s3 += f' {cmd_line}'

    return '#if 0\n' + s0 + s1 + '\n' + s2 + '\n' + s3 + '\n' + s4 + s0 + '#endif\n\n' + h_indent


def get_cmsis_header_file(hdr_name, fetch=True, save=False):
    txt = read_cmsis_header_file(hdr_name, fetch, save)
    if not txt:
        return ''

    global macro_definition, peripheral_data, uniq_type, uniq_addr, typedef_list, irq_list
    macro_definition = parse_macro_def(txt)

    typedef = []
    for peripheral_data in macro_definition:
        if 'TypeDef*' in peripheral_data[2] and 'IS_' != peripheral_data[0][:3]:
            uniq_type.add(peripheral_data[2][:-1])
            uniq_addr.add(peripheral_data[1])
            typedef.append([peripheral_data[1], peripheral_data[0], peripheral_data[2], peripheral_data[3]])

    p_list = sorted(typedef)

    peripheral_data = [p_list[xg] for xg in range(len(p_list)) if xg not in get_dupe_list(p_list)]

    peripheral_list = list(get_type_list(txt))

    for per_data in peripheral_list:
        register_dic[per_data[0]] = per_data[2]

    typedef_list = [zg[0] for zg in peripheral_list]

    irq_list = get_irq_list(txt)

    return txt


def get_peripheral_description(src):
    m = re.findall(r'Peripheral_registers_structures(.*?)Peripheral_memory_map', src, re.MULTILINE | re.DOTALL)
    type_def = re.findall(r'(.*?)\s*}\s*(\w*?TypeDef);', m[0], re.MULTILINE | re.DOTALL)
    for ix in type_def:
        pg = re.findall(r'/\*\*[^*].*?@brief\s*(.*?)\s*\*/', ix[0], re.MULTILINE | re.DOTALL)
        yield ix[1], pg[0] if pg else ''


def expand_macrodef(src_txt, macro_def_list, macro_def_dict):
    while True:
        replaced = 0
        for lx in macro_def_list:
            lx[1] = re.sub(r'([()+\-|~&*/])', ' \\1 ', lx[1], 0)  # separate some chars by spaces: '(' --> ' ( '

            es = ''
            for y_num in lx[1].split():
                if y_num in macro_def_dict:
                    d, xc = macro_def_dict[y_num]
                    if xc and '_BASE' not in lx[0]:
                        lx[3] = xc
                    replaced += 1
                else:
                    d = y_num
                es += d
            lx[1] = es

        if replaced == 0:
            break

    per_desc = list(get_peripheral_description(src_txt))  # extract peripheral description

    for lx in macro_def_list:
        if 'TypeDef*)' in lx[1]:
            q = re.findall(r'(\([A-Za-z].*TypeDef\*\))', lx[1])
            if q:
                lx[2] = q[0].strip('(').strip(')').strip()
                for ly in per_desc:
                    if ly[0] == lx[2][:-1]:
                        # insert peripheral description
                        if 'TIM' in lx[0] and ('TIM Timers' == ly[1] or 'TIM' == ly[1]):
                            lx[3] = 'Timer peripheral'
                        elif 'UART' == lx[0][:4] and 'Universal Synchronous Asynchronous Receiver Transmitter' == ly[1]:
                            w = ly[1].split()
                            lx[3] = ' '.join([w[0], w[2], w[3], w[4]])  # drop 'synchronous' word
                        elif 'DMA_Stream_TypeDef' == ly[0] and 'DMA Controller' == ly[1]:
                            lx[3] = 'DMA Stream'
                        elif '_Channel' in lx[0] and 'DMA_Channel_TypeDef' == ly[0] and 'DMA Controller' == ly[1]:
                            lx[3] = 'DMA Channel'
                        elif '_CSELR' in lx[0] and 'DMA_Request_TypeDef' == ly[0] and '' == ly[1]:
                            lx[3] = 'DMA Channel Selector'
                        elif 'BDMA' in lx[0] and 'BDMA_TypeDef' == ly[0]:
                            lx[3] = 'Basic DMA Controller'
                        elif 'DMA_TypeDef' in ly[0] and '' == ly[1]:
                            lx[3] = 'Direct Memory Access Controller'
                        elif 'LCD' == lx[0] and 'LCD' == ly[1]:
                            lx[3] = 'Liquid Crystal Display Controller'
                        elif 'RNG' == lx[0] and 'RNG' == ly[1]:
                            lx[3] = 'Random Number Generator'
                        elif 'DCMI' == lx[0] and 'DCMI' == ly[1]:
                            lx[3] = 'Digital Camera Interface'
                        elif 'LPTIM' in lx[0] and ('LPTIMER' == ly[1] or 'LPTIMIMER' == ly[1]):
                            lx[3] = 'Low Power Timer Peripheral'
                        elif 'LPUART' in lx[0] and 'Universal Synchronous Asynchronous Receiver Transmitter' == ly[1]:
                            lx[3] = 'Low Power UART Peripheral'
                        elif 'UCPD' == lx[0][:4] and 'UCPD' == ly[1]:
                            lx[3] = 'USB-C Power Delivery'
                        elif 'CORDIC' == lx[0][:6] and 'CORDIC' == ly[1]:
                            lx[3] = 'CORDIC Accelerator'
                        elif 'FMAC' == lx[0][:4] and 'FMAC' == ly[1]:
                            lx[3] = 'Filter Math Accelerator'
                        elif 'VREFBUF' in lx[0] and 'VREFBUF' == ly[1]:
                            lx[3] = 'Voltage Reference Buffer'
                        elif 'COMP' in lx[0] and 'COMP_TypeDef' == ly[0] and '' == ly[1]:
                            lx[3] = 'Analog Comparator'
                        elif 'HRTIM' in lx[0] and '' == ly[1]:
                            lx[3] = 'High Resolution Timer Peripheral'
                        elif 'DMAMUX' in lx[0] and 'Channel' in lx[0] and '' == ly[1]:
                            lx[3] = 'DMA Request Router Channel'
                        elif 'DMAMUX' in lx[0] and 'RequestGenerator' in lx[0] and '' == ly[1]:
                            lx[3] = 'DMAMUX Request Generator'
                        elif 'DMAMUX' in lx[0] and '' == ly[1]:
                            lx[3] = 'DMA Request Router'
                        elif 'MDIOS' == lx[0] and 'MDIOS' == ly[1]:
                            lx[3] = 'Management Data Input/Output Slave'
                        elif 'RAMECC' in lx[0] and '' == ly[1]:
                            lx[3] = 'RAM ECC Monitoring Unit'
                        elif 'MDMA' in lx[0] and 'Channel' in lx[0] and '' == ly[1]:
                            lx[3] = 'Master DMA Controller Channel'
                        elif 'MDMA' in lx[0] and 'MDMA Controller' == ly[1]:
                            lx[3] = 'Master DMA Controller'
                        elif 'BDMA' in lx[0] and 'Channel' in lx[0] and '' == ly[1]:
                            lx[3] = 'Basic DMA Controller Channel'
                        else:
                            lx[3] = ly[1].replace('_', ' ').strip()

                es = re.sub(r'(\([A-Za-z].*TypeDef\*\))', '', lx[1], 0)
                if es:
                    lx[1] = es

        if '_IRQn' not in lx[0]:
            # lx[1] = re.sub(r'([0-9a-fA-F])[U]|[L]', '\\1', lx[1], flags=re.I)  # strip suffixes: '0x1FUL' --> '0x1F'
            lx[1] = re.sub(r'([\da-fA-F])U|L', '\\1', lx[1], flags=re.I)  # strip suffixes: '0x1FUL' --> '0x1F'

        lx[1] = re.sub(r'\((\d{1,2})\)', '\\1', lx[1], 0)  # strip parentheses: '(21)' --> '21'

        es = ''
        if '<<' not in lx[1] and not lx[0].endswith('_Pos'):
            try:
                es = eval(lx[1])
            except (SyntaxError, NameError):
                pass

        if es != '':
            q = hex(es).split('x')
            lx[1] = f'0x{q[1].upper().rjust(8, "0")}'

        if '<<' in lx[1]:
            lx[1] = re.sub(r'0x(\d<<)', '\\1', lx[1], 0).replace('<<', ' << ')  # strip hex prefix: '0x1' --> '1'

    return macro_def_list


def parse_macro_def(macro_def_data):
    macro_def_list = []
    macro_def_dict = {}
    for lx in re.findall(r'#define\s+?(\S+?)\s+(.*?)$', macro_def_data, re.DOTALL | re.MULTILINE):
        pa = lx[0].strip()
        k = lx[1].strip()
        if k.startswith('/*'):
            # if definition has no value
            continue
        else:
            k = k.rstrip('*/').strip().split('/*')

        pb = ''
        pc = ''
        len_k = len(k)
        if len_k > 1:
            pc = k[1].strip('!<').strip()
            pb = k[0].strip()
        elif len_k > 0:
            pb = k[0].strip()

        macro_def_list.append([pa, pb, pc, ''])
        macro_def_dict.update({pa: [pb, pc]})
    return expand_macrodef(macro_def_data, macro_def_list, macro_def_dict)


def is_num_ended(a_str):
    if a_str == '':
        return '', ''

    for ax in range(len(a_str) - 1, -1, -1):
        if a_str[ax] not in '1234567890':
            return a_str[:ax + 1], a_str[ax + 1:]

    return '', a_str


def get_reg_set(reg_str, macro_def_list):
    for gx in macro_def_list:
        if gx[0].startswith(reg_str):
            if gx[0][-4] == '_' and gx[0][-3:] in {'Pos', 'Msk'}:
                continue

            if args.cpu[:1] != '3' and args.cpu[:1] != '7':
                if '_AFRL_AFRL' in gx[0] or '_AFRH_AFRH' in gx[0]:
                    continue

            if args.cpu[:2] != 'h7' and args.cpu[:2] != 'L0':
                if '_MODER_MODE' in gx[0] and gx[0][15] in '0123456789':
                    continue

            if args.cpu[:1] != '0' and args.cpu[:1] != '3' and args.cpu[:2] != 'L0' and args.cpu[:2] != 'L1':
                if '_OTYPER_OT_' in gx[0]:
                    continue

            if args.cpu[0:1] != '0' and args.cpu[0:1] != '3' and args.cpu[:1] != '7' and args.cpu[:2] != 'L1':
                if '_PUPDR_PUPDR' in gx[0]:
                    continue

            if '_IDR_IDR_' in gx[0] and args.cpu[:2] != 'L1':
                continue

            if '_ODR_ODR_' in gx[0] and args.cpu[:2] != 'L1':
                continue

            if 'RCC_AHBENR_TSEN' == gx[0]:
                continue

            if args.cpu[0:1] != '0' and args.cpu[0:1] != '3' and args.cpu[0:2] != 'L0' and args.cpu[:2] != 'L1':
                if '_BSRR_BS_' in gx[0] or '_BSRR_BR_' in gx[0]:
                    continue

            sa1, sb1 = is_num_ended(gx[0])
            if sa1[-1] == '_' and sb1 != '':  # if string ends with _1 or _2 or .. _9876543210 etc.
                gx[2] = '  ' + gx[2].strip()

            yield gx


def get_init_block(src, target):
    global macro_definition

    if not macro_definition:
        macro_definition = parse_macro_def(src)

    for lx in target:

        r_name = lx.upper().split('->')

        if args.exclude and r_name[1] in args.exclude:
            continue

        r_name[0] = strip_suffix(r_name[0])

        if 'AFR[0]' == r_name[1]:
            r_name[1] = 'AFRL'
        elif 'AFR[1]' == r_name[1]:
            r_name[1] = 'AFRH'
        elif 'EXTICR[0]' == r_name[1]:
            r_name[1] = 'EXTICR1'
        elif 'EXTICR[1]' == r_name[1]:
            r_name[1] = 'EXTICR2'
        elif 'EXTICR[2]' == r_name[1]:
            r_name[1] = 'EXTICR3'
        elif 'EXTICR[3]' == r_name[1]:
            r_name[1] = 'EXTICR4'

        if (args.cpu[0] == '3' or args.cpu[0:2] == 'L0' or args.cpu[0:2] == 'L1') and r_name[1] == 'OSPEEDR':
            r_name[1] = 'OSPEEDER'

        if r_name[0] == 'LPUART':
            r_name[0] = 'USART'

        if r_name[0] == 'UART':
            r_name[0] = 'USART'

        if r_name[0] == 'FIREWALL':
            r_name[0] = 'FW'

        if 'DMA' in r_name[0] and '_CHANNEL' in r_name[0]:
            r_name[0] = 'DMA'

        if 'DMA' in r_name[0] and '_STREAM' in r_name[0]:
            r_name[0] = 'DMA'
            r_name[1] = 'Sx' + r_name[1]

        # bitfield data is a list like this: [['TIM_CR1_CEN', '(1 << 0)', 'Counter enable', '0x00000001'] ... [ ... ]]
        bitfield_data = list(get_reg_set(f'{r_name[0]}_{r_name[1]}_', macro_definition))

        # find max length of each field
        for bit_field in bitfield_data:
            for fndx, field_len in enumerate(max_field_len):
                fl = len(bit_field[fndx])
                if field_len < fl:
                    max_field_len[fndx] = fl

            # shift field 3 into field 2 if empty
            if bit_field[2].strip() == '':
                bit_field[2] = bit_field[3]
                bit_field[3] = ''

        yield bitfield_data


def ch_def_name(def_name):
    d_name = def_name
    if 'RTC_BKP' in def_name:
        d_name = def_name.replace('BKP', 'BKUP')
    if 'USB_EP' in def_name:
        d_name = def_name.replace('_EP', '_ENP')
    if 'USB_CNTR' == def_name:
        d_name = 'USB_CTLR'
    if 'USB_ISTR' == def_name:
        d_name = 'USB_INTSTR'
    if 'USB_FNR' == def_name:
        d_name = 'USB_FRNR'
    if 'USB_DADR' == def_name:
        d_name = 'USB_DEVADDR'
    if 'USB_BTABLE' == def_name:
        d_name = 'USB_BUFTABLE'
    return d_name


def compose_reg_init_block(reg_name, bit_def, set_bit_list, comment=('', '')):
    s0 = bit_def_base = bitfield_block = assign_block = rcc_enabler = ''
    global init_macro_name

    if bit_def:
        ms = bit_def[0][0].split('_')[0:2]
        bit_def_base = f'{"_".join(ms)}_'

    rn = reg_name.split('->')[1]

    idn = 1
    if args.mix is True or args.direct is True:
        idn = 2

    lf = '\\\n'
    if args.direct:
        lf = '\n'

    if not args.direct_init or rn not in args.direct_init:

        for lx in bit_def:

            # if lx[0] == 'RCC_AHBENR_TSEN':
            #     continue

            cn = '|  /* '
            if lx == bit_def[-1]:
                cn = ' ' + cn[1:]

            bitfield_enable = '0'
            bitfield_indent = 13

            if set_bit_list:
                if lx[0] in set_bit_list:
                    bitfield_enable = '1'

                bf = lx[0].replace(bit_def_base, '')
                if bf:
                    for bit_mnem in set_bit_list:
                        if bit_mnem == bf:
                            bitfield_enable = '1'.ljust(bitfield_indent) if 'ENR_' in lx[0] else '1'

            if not args.no_macro and bitfield_enable == '0':
                if lx[0].startswith('RCC_') and lx[0].endswith('EN'):
                    bf = lx[0].split('_')
                    if 'ENR' in bf[1] and 'SMENR' not in bf[1]:
                        bitfield_enable = f'{bf[-1][:-2]}_EN'

                        rcc_enabler += f'#if !defined({bitfield_enable})\n'
                        rcc_enabler += f'{indent}#define {bitfield_enable} 0\n'
                        rcc_enabler += f'#endif\n\n'

                        bitfield_enable = bitfield_enable.ljust(bitfield_indent)

            s0 += f'{indent * idn}{bitfield_enable} * {lx[0].ljust(max_field_len[0] + 1)}{cn}'\
                  f'{lx[1].ljust(max_field_len[1] + 2)}{lx[2].ljust(max_field_len[2] + 1)}{lx[3].ljust(11)} */{lf}'

    else:
        b_ndx = args.direct_init.index(rn)
        s0 = f'{indent * idn}{args.direct_init[b_ndx + 1]} {lf}'

    if args.direct:
        assign_block = s0
    else:
        bitfield_block = s0

    if comment:
        reg_comment = comment[0]
        reg_address = comment[1]
        while '  ' in reg_comment:
            reg_comment = reg_comment.replace('  ', ' ')

        reg_comment = f'/* {reg_address}: {reg_comment.ljust(max_field_len[1] + max_field_len[2] + 17)} */'
    else:
        reg_comment = ''

    idn = 0
    if args.mix is True:
        idn = 1

    lj12 = max_field_len[0] + 12

    if args.direct:
        if assign_block != '':
            assign_block = f'{indent}{reg_name} = ('.ljust(lj12) + f'{reg_comment}\n{assign_block}{indent});\n'
        else:
            assign_block = f'{indent}{reg_name} = 0000;'.ljust(lj12) + f'{reg_comment}\n'

    else:
        macro_name = ch_def_name(reg_name.replace('->', '_').replace('[', '_').replace(']', ''))
        init_macro_name.add(macro_name)
        flen = (9 - ((not idn) * 2))

        if bitfield_block != '':
            s_pos = bitfield_block.find('|')
            bitfield_block = f'{indent * idn}#define {macro_name} ('.ljust(s_pos) +\
                             f'\\\n{bitfield_block}{indent * idn})'

            if not args.mix:
                bitfield_block += '\n'

            if args.undef is False:

                if not args.light:
                    assign_block = f'{indent}#if defined {macro_name}\n{indent * 2}#if {macro_name} != 0\n'\
                                   f'{indent * 3}{reg_name} = {macro_name};'.ljust(lj12) + \
                                   f' {reg_comment}\n{indent * 2}#endif\n'\
                                   f'{indent}#else\n{indent * 2}#define {macro_name} 0\n{indent}#endif\n'
                else:
                    assign_block = f'{indent}#if {macro_name} != 0\n'\
                                   f'{indent * 2}{reg_name} = {macro_name};'.ljust(lj12) + \
                                   f' {reg_comment}\n{indent}#endif\n'

            else:
                assign_block = f'{indent}#if {macro_name} != 0\n{indent * 2}{reg_name} = {macro_name};'.ljust(lj12) +\
                               f' {reg_comment}\n{indent}#endif'

        else:
            bitfield_block = f'{indent * idn}#define {macro_name} '.ljust(max_field_len[0] + flen) + '0000\n'
            if not args.light:
                assign_block = f'{indent}#if defined {macro_name}\n{indent * 2}#if {macro_name} != 0\n'\
                               f'{indent * 3}{reg_name} = {macro_name};'.ljust(lj12) +\
                               f' {reg_comment}\n{indent * 2}#endif\n'\
                               f'{indent}#else\n{indent * 2}#define {macro_name} 0\n{indent}#endif\n'
            else:
                assign_block = f'{indent}#if {macro_name} != 0\n{indent * 2}{reg_name} = {macro_name};'.ljust(lj12) +\
                               f' {reg_comment}\n{indent}#endif\n'

        if args.undef is True:
            assign_block += f'\n{indent}#undef {macro_name}\n'

    bitfield_block = rcc_enabler + '\n' + bitfield_block

    return bitfield_block, assign_block


def make_init_func(func_name, func_body, header='', footer=''):
    hdr = ftr = ''
    if header:
        hdr = f'{indent}\n'.join(header) + '\n\n'

    if args.pre_init:
        hdr += f'{indent}/* Perform pre-configuration of the hardware */\n'

        for f_name in args.pre_init:
            hdr += f'{indent}{f_name}();\n'

    if args.post_init:
        ftr = f'\n{indent}/* Perform additional setup after initialization */\n'
        for f_name in args.post_init:
            ftr += f'{indent}{f_name}();\n'

    if footer:
        ftr += f'\n{indent}'.join(footer) + '\n'
        ftr = f'\n{indent}{ftr}'

    return f'__STATIC_INLINE void {func_name}(void) {{\n\n{hdr}\n{func_body}{indent}{ftr}\n}}'


def make_h_module(module_name, module_body):
    mn = module_name.upper()
    return f'#ifndef __{mn}_H__\n#define __{mn}_H__\n\n#ifdef __cplusplus\n  extern "C" {{\n#endif\n\n' \
           f'{module_body}\n#ifdef __cplusplus\n  }}\n#endif /* __cplusplus */\n' + f'#endif /* __{mn}_H__ */\n'


def compose_init_block(src, reg_set, set_bit_list, comment=('', '')):
    fx = list(get_init_block(src, reg_set))
    block_a = []
    block_b = []
    for lx in range(len(fx)):
        bl_a, bl_b = compose_reg_init_block(reg_set[lx], fx[lx], set_bit_list, comment)
        block_a.append(bl_a)
        block_b.append(bl_b)

    return block_a, block_b


def get_reg_size(sz):
    if 'uint32_t' in sz:
        return '4'
    elif 'uint16_t' in sz:
        return '2'
    elif 'uint8_t' in sz:
        return '1'
    else:
        return 'X'


def get_type_list(src):
    type_def = re.findall(r'typedef\s+struct\s*{\s*(\w.*?)\s*}\s*(\S*?TypeDef)\s*;', src, re.MULTILINE | re.DOTALL)

    for gx in type_def:
        t_list = []
        for gy in gx[0].replace(';/', '; /').split('\n'):

            if 30 * ' ' == gy[:30]:
                # do not parse multiline comments
                continue

            gs = gy.strip()
            if '' == gs or '//' == gs[:2]:
                # do not parse empty or commented out strings
                continue

            while ' ;' in gs:
                gs = gs.replace(' ;', ';')

            w = gs.split()

            reg_size = get_reg_size(gs)

            rname = ''
            for gz in w:  # for every word in the string...
                if gz.endswith(';'):
                    rname = gz
                    break

            if gs.startswith('__IO') or gs.startswith('__I') or gs.startswith('__O'):
                register_name = rname[:-1]
            else:
                register_name = w[1][:-1]

            if reg_size == 'X':
                reg_size = w[0]

            gc = re.findall(r'/\*\s*(.*?)\s*\*/', gs)
            register_comment = gc[0].lstrip('!').lstrip('<').lstrip() if len(gc) > 0 else ''

            t_list.append([register_name, reg_size, register_comment])

        yield [gx[1], '0x' + '0' * 8, t_list]


def get_dupe_list(dev_list):
    to_be_del = []
    for dx in range(len(dev_list)):
        if dx > 0:
            if (dev_list[dx][0] == dev_list[dx - 1][0]) and (dev_list[dx][2] == dev_list[dx - 1][2]):
                if '_' not in dev_list[dx - 1][1]:
                    dev_name_1 = dev_list[dx - 1][1]
                else:
                    dev_name_1 = dev_list[dx - 1][1].split('_')[0]

                if '_' not in dev_list[dx][1]:
                    dev_name_2 = dev_list[dx][1]
                else:
                    dev_name_2 = dev_list[dx][1].split('_')[0]

                if dev_name_1 == dev_name_2 + '1':
                    to_be_del.append(dx)
                elif dev_name_2 == dev_name_1 + '1':
                    to_be_del.append(dx - 1)

                if dev_name_1 == 'ADC' and dev_name_2 == 'ADC123':
                    to_be_del.append(dx - 1)
                elif dev_name_1 == 'ADC123' and dev_name_2 == 'ADC':
                    to_be_del.append(dx)
    return to_be_del


def is_hex(num_str):
    try:
        int(num_str, 16)
        return True
    except ValueError:
        return False


def strip_suffix(peripheral_name):
    """ Strip number from peripheral name. Example: 'TIM10' ==> 'TIM' or 'GPIOC' ==> 'GPIO' """
    pn = peripheral_name
    while True:
        if pn[-1] in '0123456789' or pn[:-1] == 'GPIO':
            pn = pn[:-1]
        else:
            break
    return pn


def find_peripheral(peripheral_name):
    """ return address and typedef name of the peripheral. Example: ('TIM3', '0x40000400', 'TIM_TypeDef') """
    pn = peripheral_name.strip()
    for xc in peripheral_data:
        if args.strict is False:
            if pn in xc[1]:
                yield xc[1], xc[0], xc[2][:-1]
        else:
            if pn == xc[1]:
                yield xc[1], xc[0], xc[2][:-1]


def get_register_set(peripheral_name):
    pn = strip_suffix(peripheral_name)
    dict_key = f'{pn}_TypeDef'
    if dict_key in register_dic:
        return register_dic[dict_key]
    return []


def get_register_size(struct_name):
    reg_size = 0

    if struct_name == 'AND':
        return reg_size

    if not struct_name.isdigit():
        for xr in register_dic[struct_name]:
            reg_size += get_register_size(xr[1])
    else:
        reg_size = int(struct_name)

    return reg_size


def get_register_property(reg_name):
    left_bracket = reg_name[0].find('[')
    right_bracket = reg_name[0].find(']')
    arr_size = reg_name[0][left_bracket + 1:right_bracket]

    if all([sg.isdigit() for sg in arr_size]):
        for x_ndx in range(int(arr_size)):
            yield reg_name[0][:left_bracket + 1] + str(x_ndx) + ']', get_register_size(reg_name[1])
    else:
        yield reg_name[0], get_register_size(reg_name[1])


def get_register_list(peripheral_property):
    register_address = 0
    for pp in register_dic[peripheral_property[2]]:
        for reg_name, reg_offs in get_register_property(pp):
            if 'RESERVED' not in reg_name.upper():
                yield [reg_name, pp[2], f'0x{int(peripheral_property[1], 16) + register_address:X}']

            register_address += int(reg_offs)


def get_peripheral_register_list(peripheral_name):
    for pe in find_peripheral(peripheral_name):  #
        if is_hex(pe[1]):
            yield pe[0], get_register_list(pe)

    if peripheral_name == 'USART':
        for pe in find_peripheral('UART'):  #
            if is_hex(pe[1]):
                yield pe[0], get_register_list(pe)


def sort_peripheral_by_num(periph):
    k = periph[0]
    pn = ''
    while True:
        if k[-1] in '0123456789':
            pn = k[-1] + pn
            k = k[:-1]
        else:
            break
    if pn != '':
        return int(pn)
    else:
        return 0


def_sort_list = [
    ('LPUART', 'XUART'), ('UART', 'USART'), ('ISR', 'VV0'), ('UART', 'USART'), ('ISR', 'VV0'), ('DR', 'WR'),
    ('ICR', 'VV1'), ('CNT', 'WW1'), ('RDR', 'WW0'), ('TDR', 'WW1'), ('PSC', 'AA0'),
    ('EGR', 'AS0'), ('MODER', 'AA0'), ('BRR', 'AB0'), ('_CR', '_C0'), ('DIER', 'C10'), ('IER', 'CGR'),
    ('RCR', 'C20'), ('CCMR', 'C30'), ('CCER', 'C40'), ('SMCR', 'C50'), ('BDTR', 'U00'),
    ('_SR', '_U10'), ('AHBENR', 'A10'), ('AHB1ENR', 'A20'), ('AHB2ENR', 'A30'), ('AHB3ENR', 'A40'),
    ('APB1ENR', 'A50'), ('APB2ENR', 'A60'), ('CFGR', 'A70'), ('CSR', 'A80'), ('LCD_CLR', 'LCD_U20'),
    ('LCD_RAM_10', 'LCD_RAM_A'), ('LCD_RAM_11', 'LCD_RAM_B'), ('LCD_RAM_12', 'LCD_RAM_C'), ('LCD_RAM_13', 'LCD_RAM_D'),
    ('LCD_RAM_14', 'LCD_RAM_E'), ('LCD_RAM_15', 'LCD_RAM_F'), ('LPTIM', 'XTIM'), ('QUADSPI', 'XSPI'),
    ('ADC123', 'ADCT'), ('ADC12', 'ADCU'), ('ADC1_2', 'ADCU'), ('AWD', 'TTD'), ('CALFACT', 'TTF')
]

ini_sort_list = [
    ('LPUART', 'XUART'), ('UART', 'USART'), ('OR', 'ZX1'), ('CCR1', 'CCR0'), ('ISR', 'VV0'),
    ('ICR', 'VV1'), ('RDR', 'WW0'), ('TDR', 'WW1'), ('BRR', 'AAA'), ('PSC', 'AA0'), ('CR1', 'ZZ1'),
    ('EGR', 'ARS'), ('CCER', 'DDER'), ('LPTIM', 'XTIM'), ('AHBENR', 'A10'), ('AHB1ENR', 'A20'), ('AHB2ENR', 'A30'),
    ('AHB3ENR', 'A40'), ('APB1ENR', 'A50'), ('APB2ENR', 'A60'), ('CFGR', 'A70'), ('CSR', 'A80'),
    ('LCD_CLR', 'LCD_U20'), ('LCD_CR', 'LCD_XR'), ('QUADSPI', 'XSPI'), ('XSPI_CR', 'XSPI_XR'), ('DCR', 'U20'),
    ('DMAR', 'U40'), ('BDTR', 'U60'), ('CR', 'ZZ0'), ('AWD', 'TTD'), ('CALFACT', 'TTF')
]


def sort_code_block(code_block, rep_list):
    if len(code_block) > 0 and code_block[0] != '':
        ret_name = code_block[0]
    else:
        return ''

    for xsrc, xdst in rep_list:
        ret_name = ret_name.replace(xsrc, xdst)

    for xtr in range(10, 99):
        tim = 'TIM'
        d1 = xtr % 10
        d2 = xtr // 10
        tm = tim + str(xtr)
        if tm in ret_name:
            ret_name = ret_name.replace(tm, tim + chr(ord('A') + d1) + chr(ord('A') + d2))

    return ret_name


def sort_ini_block(initialization_block):
    return sort_code_block(initialization_block, ini_sort_list)


def sort_def_block(definition_block):
    return sort_code_block(definition_block, def_sort_list)


def sort_peripheral_by_suffix(peripheral_name):
    # Extract the digits from the string and return them as a number for comparison
    try:
        sfx = int(''.join(filter(str.isdigit, peripheral_name)))
    except ValueError:
        sfx = 0

    return sfx


def make_definition_block():
    indx = 0
    dstr = '\n'
    while len(args.define) > indx:
        if args.define[indx] != '':
            dstr += f'#define {args.define[indx]}'.ljust(31)
        else:
            dstr += '\n'
            indx += 1
            continue

        indx += 1
        if indx == len(args.define):
            break
        if args.define[indx] != '' and args.define[indx].strip() == '':
            dstr = dstr.rstrip() + '\n'
        else:
            dstr += f'{indent * 4}{args.define[indx]}\n'
        indx += 1
    return dstr


if __name__ == '__main__':

    if '-V' in sys.argv or '--version' in sys.argv:
        print('0.083a\n')
        exit()

    import argparse

    parser = argparse.ArgumentParser(prog='stm32cgen', description='STM32 initialization generator')
    parser.add_argument('-V', '--version', action="store_true", help="show version and exit")
    parser.add_argument('cpu', metavar='cpu_name', help='abbreviated MCU name. I.e. "103c8", "g031f6", "h757xi" etc.')
    parser.add_argument('-d', '--direct', action="store_true", default=False, help="No predefined macros")
    parser.add_argument('--dummy', nargs='+', help="dummy parameter(s)")
    parser.add_argument('-D', '--define', nargs='+', help="add a MACRO to the header")
    parser.add_argument('-H', '--header', nargs='+', help="add strings to header")
    parser.add_argument('-E', '--peripheral-enable', nargs='+', help="add _EN MACRO to the footer")
    parser.add_argument('-F', '--footer', action='append', help="add strings to the footer")
    parser.add_argument('-R', '--disable-rcc-macro', action="store_true", default=False)
    parser.add_argument('-l', '--no-fetch', action="store_true", default=False, help="Do not fetch header file")
    parser.add_argument('-u', '--undef', action="store_true", default=False,
                        help="place #undef for each initialization definition")
    parser.add_argument('--mix', action="store_true", default=False,
                        help="mix definition and initialization blocks of code")
    parser.add_argument('--light', action="store_true", default=False,
                        help="use light initialization codeblocks")
    parser.add_argument('--save-header-file', action="store_true", default=False, help='write fetched file to disk')
    parser.add_argument('--strict', action="store_true", default=False, help="strict matching only")
    parser.add_argument('-i', '--indent', type=int, default=2, help="set the indentation for code in spaces")
    parser.add_argument('-I', '--direct-init', nargs='+', help="init the registers by instant values")
    parser.add_argument('-m', '--module', help="produce output in the form of a header file")
    parser.add_argument('-M', '--main-module', action="store_true", help="create main.h content")
    parser.add_argument('--pre-init', nargs=1, default=False, help="add pre_init() function")
    parser.add_argument('--post-init', nargs=1, default=False, help="add post_init() function")
    parser.add_argument('--uncomment', nargs='+', default=False, help="enable commented out #include directive(s)")
    parser.add_argument('-n', '--no-macro', action="store_true", default=False,
                        help="disable peripheral-specific macros")
    parser.add_argument('-f', '--function', help="place code into a function")
    parser.add_argument('--function-header', nargs='+', help="add string to the top of function")
    parser.add_argument('--function-footer', nargs='+', help="add string to the bottom of function")
    parser.add_argument('-p', '--peripheral', nargs='+', help="use specified peripheral(s)")
    parser.add_argument('-q', '--irq', action="store_true", help="irq property")
    parser.add_argument('-r', '--register', nargs='+', help="process the registers specified")
    parser.add_argument('-t', '--test', action="store_true", help="test experimental feature")
    parser.add_argument('-b', '--set-bit', nargs='+', help="set the bits ON")
    parser.add_argument('-v', '--verbose', action="store_true", help="produce verbose output")
    parser.add_argument('-X', '--exclude', nargs='+', help="exclude the registers from processing")

    args = parser.parse_args()

    cpu_name = args.cpu.upper()

    if cpu_name[0:5] == 'STM32':
        cpu_name = cpu_name[5:]

    if cpu_name[0] == 'F':
        cpu_name = cpu_name[1:]

    if cpu_name[0] == 'L' or cpu_name[0] == 'H' or cpu_name[0] == 'G':
        cpu_name = cpu_name[:6]
    elif cpu_name[0] in '1234567890':
        cpu_name = cpu_name[:5]
    else:
        print(f'wrong parameter passed: {args.cpu}')
        exit()

    args.cpu = cpu_name

    if args.verbose:
        print('Parameters passed', len(sys.argv))
        print(args)

    s_data = get_cmsis_header_file(args.cpu, fetch=not args.no_fetch, save=args.save_header_file)

    if args.test:
        strict = args.strict
        args.strict = True

        periph_data = {}
        for x_per in peripheral_data:
            # x_per is the peripheral data like this: ['0x40000000', 'TIM2', 'TIM_TypeDef*', 'Timer peripheral']
            r = {}
            for name, lst, in sorted(list(get_peripheral_register_list(x_per[1])), key=sort_peripheral_by_num):
                for rg in lst:
                    # here rg is the list in form of ['REGISTER_NAME', 'Register description', 'Register address']
                    bf_dic = {}
                    for bif in list(get_init_block(s_data, [f'{name}->{rg[0]}']))[0]:
                        # bif is the set of bitfield data like this:
                        #                               ['TIM_CR1_CEN', '(1 << 0)', 'Counter enable', '0x00000001']
                        bit_key = bif[0].split('_')[2:][0]
                        bf_dic[bit_key] = Bit([bif[1], bif[3], bif[2]])

                    register_size = 0
                    for x_reg in register_dic[x_per[2][:-1]]:
                        if rg[0] == x_reg[0]:
                            register_size = x_reg[1]
                            break

                    r[rg[0]] = Register([rg[2], register_size, rg[1], bf_dic])

            periph_data[x_per[1]] = Peripheral([x_per[0], x_per[2], x_per[3], r])

        uc = Microcontroller(args.cpu, "STM32 Microcontroller", periph_data)

        args.strict = strict

        s_temp = ''
        for x1 in uc.peripheral.keys():
            s_temp += x1 + '\n'
            for x2 in uc.peripheral[x1].register.keys():
                s_temp += f'          {x2}@{uc.peripheral[x1].register[x2].address}\n'

    adcen = 'ENR_ADCEN' in s_data
    dmaen = 'ENR_DMAEN' in s_data
    dma1en = 'ENR_DMA1EN' in s_data
    dma2en = 'ENR_DMA2EN' in s_data

    if not s_data:
        print(f'unable to get data for "{args.cpu}"')
        exit()

    tblock = []
    enabler = []
    stout = ''

    code_block_def = []
    code_block_ini = []
    irqlist = []
    if args.peripheral:
        for p in args.peripheral:
            j_sorted = sorted(list(get_peripheral_register_list(p)), key=sort_peripheral_by_num)
            for name, lst, in j_sorted:
                for rg in lst:
                    # 'rg' is a list of register attributes in the form of ['REGISTER_NAME', 'DESCR', 'ADDRESS']

                    if args.exclude and rg[0] in args.exclude:
                        # do not process register if it is in exclude list
                        continue

                    if args.register and rg[0] not in args.register:
                        # do not process register outside the list
                        continue

                    sa, sb = compose_init_block(s_data, [name + '->' + rg[0]], args.set_bit, (rg[1], rg[2]))

                    if sa:
                        code_block_def.append(sa)
                        code_block_ini.append(sb)

                for xirq in irq_list:
                    if name == xirq[0].split('_')[0]:
                        irqlist.append(xirq)

                if args.undef is False:
                    x_out = f'( \\\n{indent}'
                    for cnt, ds in enumerate(sorted(init_macro_name), start=1):
                        x_out += f'({ds} != 0) || '
                        if cnt % 5 == 0:
                            x_out += f'\\\n{indent}'

                    if len(init_macro_name) % 5 == 0:
                        x_out = x_out[:-4]

                    if 'DMA' == name[:3] and len(name) < 6:
                        name = name + '_STATUS'

                    if 'QUADSPI' == name[:8] and len(name) < 9:
                        name = name[0] + name[4:]

                    if 'FIREWALL' == name:
                        name = 'FW'

                    if name in ['RCC']:
                        pass
                    else:
                        enabler.append(f'{name}_EN')
                        x_out = f'#define {enabler[-1]} {x_out[:-3]}'.strip() + ' \\\n)\n'
                        tblock.append(x_out)

                init_macro_name = set()

            if enabler and j_sorted and args.function:
                x_out = ''
                for cnt, en in enumerate(sorted(enabler), start=1):
                    x_out += f'({en} != 0) || '
                    if cnt % 5 == 0:
                        x_out += f'\\\n{indent * 3}'

                if 'DMA' in enabler[0]:

                    dma_register = [[], [], [], [], [], [], [], []]
                    dma_peripheral = ['DMA1', 'DMA2', 'DMAMUX1', 'DMAMUX2', 'BDMA1', 'BDMA2', 'BDMA', 'MDMA']

                    for en in sorted(enabler):
                        for ndx1 in range(len(dma_peripheral)):
                            if en.split('_')[0] == dma_peripheral[ndx1]:
                                dma_register[ndx1].append(en)

                    if dma_register[5]:
                        # if BDMA2 register is present the BDMA register data is irrelevant
                        dma_register[6] = []

                    for ndx1 in range(len(dma_peripheral)):
                        if dma_register[ndx1]:
                            st = ''
                            for cnt, en in enumerate(sorted(dma_register[ndx1]), start=1):
                                st += f'({en} != 0) || '
                                if cnt % 4 == 0 and len(dma_register[ndx1]) != cnt:
                                    st += f'\\\n{indent * 3}'
                            tblock.append(f'#define {dma_peripheral[ndx1]}_EN ( \\\n'
                                          f'{indent}{st[:-3].replace(indent * 3, indent)}\\\n)\n')

                    x_out = ''
                    if 'DMA1_Channel1_EN' in enabler or 'DMA1_Stream1_EN' in enabler:
                        x_out = 'DMA1_EN'
                    if 'DMA2_Channel1_EN' in enabler or 'DMA2_Stream1_EN' in enabler:
                        if '' != x_out:
                            x_out += ' || DMA2_EN'
                        else:
                            x_out = 'DMA2_EN'

                    x_out += '   '

                x_out = f'#if 0\n{indent}#if {x_out[:-3]}\n{indent * 2}{args.function}();\n{indent}#endif\n#endif\n'

                tblock.append(x_out)

        def_block = init_block = ''
        n = '\n'

        if args.mix is False:
            code_block_def = sorted(code_block_def, key=sort_def_block)
        else:
            code_block_def = sorted(code_block_def, key=sort_ini_block)

        code_block_ini = sorted(code_block_ini, key=sort_ini_block)

        for cd, ci in zip(code_block_def, code_block_ini):
            if args.mix is False:
                def_block += cd[0] + '\n'
            else:
                init_block += cd[0] + '\n'

            init_block += ci[0] + '\n'

        def_block = def_block.strip('\n')
        init_block = init_block.strip('\n')

        irqstr = ''
        ind = f'{indent}NVIC_'
        for xirq in irqlist:
            irqstr += f'\n#if 0\n{ind}SetPriority('
            irqstr += f'{xirq[0]}, NVIC_EncodePriority(NVIC_GetPriorityGrouping(), 0, 0));\n'
            irqstr += f'{ind}ClearPendingIRQ({xirq[0]});\n'
            irqstr += f'{ind}EnableIRQ({xirq[0]});\n'
            irqstr += f'#endif\n'

        if irqstr:
            init_block += f'\n{irqstr}'

        if args.function:
            fheader = ffooter = []
            if args.function_header:
                fheader = args.function_header
            if args.function_footer:
                ffooter = args.function_footer

            stout = f'{def_block}{n * 3}{make_init_func(args.function, init_block, fheader, ffooter)}'.strip(n)
        else:
            stout = f'{def_block}{n * 2}{init_block}'

        xstr = '\n'
        if args.pre_init:
            xstr += f'__STATIC_INLINE void {args.pre_init[0]}(void);\n'
        if args.post_init:
            xstr += f'__STATIC_INLINE void {args.post_init[0]}(void);\n'

        if xstr != '\n':
            stout = xstr + '\n\n' + stout

        if args.header:
            stout = f'{n.join(args.header)}{n * 2}{stout}'

        if args.define:
            '''
            ndx = 0
            def_str = '\n'
            while len(args.define) > ndx:
                if args.define[ndx] != '':
                    def_str += f'#define {args.define[ndx]}'.ljust(22)
                else:
                    def_str += '\n'
                    ndx += 1
                    continue

                ndx += 1
                if ndx == len(args.define):
                    break
                if args.define[ndx] != '' and args.define[ndx].strip() == '':
                    def_str = def_str.rstrip() + '\n'
                else:
                    def_str += f'{indent * 4}{args.define[ndx]}\n'
                ndx += 1
                
            stout = def_str + '\n' + stout
            '''
            stout = make_definition_block() + '\n' + stout

        '''
        stout = f'{n}/* This code was created with stm32cgen for use with the {args.cpu} microcontroller.{n}'\
                f' */{n}/* Arguments used: {cmd_line} */{n * 2}{h_indent}{stout.strip()}'
        '''

        stout = f'{copyright_message(compose_cmsis_header_file_name(args.cpu))}{stout.strip()}'

        # delete all '#if 0' strings from the list except the last
        tb = [st for st in tblock if st.startswith('#if 0')]

        if len(tb) > 1:
            tblock = [st for st in tblock if '#if 0' not in st] + [tb[-1]]

        for ind, xa in enumerate(tblock, 1):
            if 'ADC1_EN' in xa and adcen:
                tblock.insert(ind, '#define ADC_EN      ADC1_EN\n')
                break

        stout += f'{n * 2}'
        if not args.direct and tblock:
            stout += f'{n.join(tblock)}{n}'

        if args.peripheral_enable:
            ndx = 0
            stout += '\n'
            while len(args.peripheral_enable) > ndx:
                stout += f'#define {args.peripheral_enable[ndx]}_EN'.ljust(32)
                ndx += 1
                if ndx == len(args.peripheral_enable):
                    stout = stout.rstrip()
                    break
                stout += f'{args.peripheral_enable[ndx]}\n'
                ndx += 1

        if args.footer:
            stout = f'{stout}{n.join(args.footer)}'

        if args.module:
            stout = make_h_module(args.module, stout)

        print(stout)

    elif args.irq:
        for xi in irq_list:
            print((xi[0] + ',').ljust(25), (xi[1] + ',').ljust(30), (xi[2] + ',').ljust(5), xi[3])

        print(f'\nTotal {len(irq_list)} IRQs.')

    elif len(sys.argv) < 4 and args.cpu != '':
        for x in peripheral_data:
            print(f'{x[1].ljust(15)} {x[0]}  {x[2][:-1].ljust(20)} "{x[3]}"')

        print()

        print(f'Peripheral count: {len(peripheral_data)} (uniq address: {len(uniq_addr)});')
        print(f'Unique type count: {len(uniq_type)} (from {len(typedef_list)} defined);')
        print(f'Extra: {len(list(set(typedef_list) - set(uniq_type)))} {list(set(typedef_list) - set(uniq_type))}')

    elif args.cpu != '' and args.main_module:

        #
        # Create main.h source file
        #

        xp = {}

        for x in peripheral_data:
            if x[2] not in xp:
                xp[x[2]] = []

            xp[x[2]].append(x[1])

        td = 'PWR_TypeDef*'
        xp = {td: xp.pop(td), **xp}

        td = 'RCC_TypeDef*'
        xp = {td: xp.pop(td), **xp}

        td = 'FLASH_TypeDef*'
        xp = {td: xp.pop(td), **xp}

        td = 'GPIO_TypeDef*'
        tp = xp.pop(td)
        xp = {**xp, td: tp}

        print('#ifndef __MAIN_H__')
        print('#define __MAIN_H__')
        print()
        print('#ifdef __cplusplus /* provide compatibility between C and C++ */')
        print('  extern "C" {')
        print('#endif')
        print()
        print(copyright_message(compose_cmsis_header_file_name(args.cpu)).strip())

        if args.define:
            print(make_definition_block())

        print()
        print(f'#include "{compose_cmsis_header_file_name(args.cpu)}" /* Include CMSIS header file */')
        print()
        print('/* Uncomment corresponding line if using the peripheral is intended. */')

        s = ''
        func_list = []
        essential_peripheral = ['flash', 'gpio', 'rcc']

        for x in xp:

            xp[x].sort(key=sort_peripheral_by_suffix)
            periph_name = x.split("_")[0].lower()

            if periph_name not in func_list:

                func_list.append(periph_name)

                if periph_name in essential_peripheral[1:]:
                    s += f'{indent}/* {periph_name.upper()} should always be initialized as it is ' \
                         f'essential peripheral for the functioning of the system. */\n'

                    s += f'{indent}init_{periph_name}();\n\n'
                else:
                    s += f'#if'
                    for y in xp[x]:
                        s += f'(defined({y}_EN) && {y}_EN)' + (' || ' if y != xp[x][-1] else '\n')
                    s += f'{indent}init_{periph_name}();\n#endif\n\n'

                if periph_name not in essential_peripheral:
                    cmark = '// '
                    if args.uncomment and periph_name in args.uncomment:
                        cmark = ''
                    print(f'{cmark}#include "{periph_name}.h"')

        cmark = '// '
        if args.uncomment and 'flash' in args.uncomment:
            cmark = ''

        print(cmark + '\n'.join([f'#include "{p}.h"' for p in essential_peripheral]).replace('\n', '\n\n', 1))
        print()
        print()

        linefeed = ''
        if args.pre_init:
            linefeed = '\n\n'
            print(f'__STATIC_INLINE void {args.pre_init[0]}(void);')
        if args.post_init:
            linefeed = '\n\n'
            print(f'__STATIC_INLINE void {args.post_init[0]}(void);')

        print(linefeed, end='')

        print('/* Initialize all the required peripherals */')
        print('__STATIC_INLINE void init(void) {')
        print()

        if args.pre_init:
            print(f'{indent}/* Perform pre-configuration of the system */')
            print(f'{indent}{args.pre_init[0]}();')
            print()

        print(s[:-1])

        if args.post_init:
            print(f'{indent}/* Perform additional setup after initialization */')
            print(f'{indent}{args.post_init[0]}();')
            print()

        print('}')
        print()

        if args.footer:
            print('\n'.join(args.footer))

        print()

        print('#ifdef __cplusplus')
        print('  }')
        print('#endif /* __cplusplus */')
        print('#endif /* __MAIN_H__ */')
        print()
