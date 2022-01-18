#!/usr/bin/env python3

import re
import sys

try:
    from stm32cmsis import read_cmsis_header_file
except ImportError:
    print('Could not import STM32 CMSIS library')
    sys.exit(1)

max_field_len = [0, 0, 0]

# all definitions from header file in the following format:
#  'MACRO_NAME',      'VALUE',                'COMMENT',                  'EXTRA_VALUE'
# ['RCC_CR_HSERDY', '(1 << 17)', 'External High Speed clock ready flag',  '0x00020000']
macro_definition = []

# typedef list for all peripherals like 'TIM_TypeDef', 'USART_TypeDef' etc.
defined_type = []

# complete list of all peripherals in the format of:
# 'HEX_ADDRESS',   'NAME',     'TYPEDEF',         'COMMENT'
# ['0x40000000',   'TIM2',   'TIM_TypeDef*',  'Timer peripheral']
peripheral = []

# peripheral registers dictionary: { "TypeDef" : [['REGISTER NAME', 'LENGTH', 'COMMENT' ],[...], ... }
# {'I2C_TypeDef': [['CR1', '4', ''], ['CR2', '4', ''], ['OAR1', '4', ''], ['OAR2', '4', ''], ['DR', '4', '']...]...}
#
register_dic = {}

uniq_type = set()
uniq_addr = set()

indent = 2 * ' '

def_set = set()


def get_cmsis_header_file(hdr_name, fetch=True, save=False):
    txt = read_cmsis_header_file(hdr_name, fetch, save)
    if not txt:
        return ''

    global macro_definition, peripheral, uniq_type, uniq_addr, defined_type
    macro_definition = parse_macro_def(txt)

    typedef_list = []
    for xg in macro_definition:
        if 'TypeDef*' in xg[2] and 'IS_' != xg[0][:3]:
            uniq_type.add(xg[2][:-1])
            uniq_addr.add(xg[1])
            typedef_list.append([xg[1], xg[0], xg[2], xg[3]])

    p_list = sorted(typedef_list)

    peripheral = [p_list[xg] for xg in range(len(p_list)) if xg not in get_dupe_list(p_list)]

    temp_list = list(get_type_list(txt))

    for xg in temp_list:
        register_dic[xg[0]] = xg[2]

    defined_type = [zg[0] for zg in temp_list]

    return txt


def get_peripheral_description(src):
    m = re.findall(r'Peripheral_registers_structures(.*?)Peripheral_memory_map', src, re.MULTILINE | re.DOTALL)
    n = re.findall(r'(.*?)\s*}\s*(\w*?TypeDef);', m[0], re.MULTILINE | re.DOTALL)
    for ix in n:
        pg = re.findall(r'/\*\*[^*].*?@brief\s*(.*?)\s*\*/', ix[0], re.MULTILINE | re.DOTALL)
        yield ix[1], pg[0] if pg else ''


def expand_macrodef(src_txt, macro_def_list, macro_def_dict):
    while True:
        replaced = 0
        for lx in macro_def_list:
            lx[1] = re.sub(r'([()+\-|~&*/])', ' \\1 ', lx[1], 0)  # separate some chars by spaces: '(' --> ' ( '

            es = ''
            for y in lx[1].split():
                if y in macro_def_dict:
                    d, xc = macro_def_dict[y]
                    if xc and '_BASE' not in lx[0]:
                        lx[3] = xc
                    replaced += 1
                else:
                    d = y
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
            lx[1] = re.sub(r'([0-9a-fA-F])[U]|[L]', '\\1', lx[1], flags=re.I)  # strip suffixes: '0x1FUL' --> '0x1F'

        lx[1] = re.sub(r'\((\d{1,2})\)', '\\1', lx[1], 0)  # strip parentheses: '(21)' --> '21'

        es = ''
        if '<<' not in lx[1] and not lx[0].endswith('_Pos'):
            try:
                es = eval(lx[1])
            except (SyntaxError, NameError):
                pass

        if es != '':
            q = hex(es).split('x')
            lx[1] = '0x' + q[1].upper().rjust(8, '0')

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
        n = len(k)
        if n > 1:
            pc = k[1].strip('!<').strip()
            pb = k[0].strip()
        elif n > 0:
            pb = k[0].strip()

        macro_def_list.append([pa, pb, pc, ''])
        macro_def_dict.update({pa: [pb, pc]})
    return expand_macrodef(macro_def_data, macro_def_list, macro_def_dict)


def is_num_ended(a_str):
    if a_str == '':
        return '', ''

    for ax in range(len(a_str) - 1, -1, -1):
        if a_str[ax] not in '1234567890':
            return a_str[:ax+1], a_str[ax+1:]

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

        c_set = list(get_reg_set(r_name[0] + '_' + r_name[1] + '_', macro_definition))

        for dx in c_set:
            for dy in range(len(max_field_len)):
                fl = len(dx[dy])
                if max_field_len[dy] < fl:
                    max_field_len[dy] = fl

            if dx[2].strip() == '':
                dx[2] = dx[3]
                dx[3] = ''

        yield c_set


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
    s0 = bitfield_block = assign_block = ''
    global def_set

    ms = bit_def[0][0].split('_')[0:2]
    bit_def_base = '_'.join(ms) + '_'

    rn = reg_name.split('->')[1]

    idn = 1
    if args.mix is True or args.direct is True:
        idn = 2

    if not args.direct_init or rn not in args.direct_init:

        for lx in bit_def:
            cn = '|  /* '
            if lx == bit_def[-1]:
                cn = ' ' + cn[1:]

            bitfield_enable = '0'

            if set_bit_list:
                if lx[0] in set_bit_list:
                    bitfield_enable = '1'

                bf = lx[0].replace(bit_def_base, '')
                if bf:
                    for bit_mnem in set_bit_list:
                        if bit_mnem == bf:
                            bitfield_enable = '1'

            if not args.disable_rcc_macro and bitfield_enable == '0':
                if lx[0].startswith('RCC_') and lx[0].endswith('EN'):
                    bf = lx[0].split('_')
                    if 'ENR' in bf[1] and 'SMENR' not in bf[1]:
                        bitfield_enable = (bf[-1][:-2] + '_EN').ljust(10, ' ')

            s0 += f'{indent * idn}{bitfield_enable} * {lx[0].ljust(max_field_len[0] + 1)}{cn}'\
                + f'{lx[1].ljust(max_field_len[1] + 2)}{lx[2].ljust(max_field_len[2] + 1)}{lx[3].ljust(11)} */'

            if args.direct:
                s0 += '\n'
            else:
                s0 += '\\\n'
    else:
        b_ndx = args.direct_init.index(rn)
        s0 = indent * idn + args.direct_init[b_ndx + 1]
        if args.direct:
            s0 += '\n'
        else:
            s0 += ' \\\n'

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
        def_name = ch_def_name(reg_name.replace('->', '_').replace('[', '_').replace(']', ''))
        def_set.add(def_name)
        flen = (9 - ((not idn) * 2))

        if bitfield_block != '':
            s_pos = bitfield_block.find('|')
            bitfield_block = f'{indent * idn}#define {def_name} ('.ljust(s_pos) + f'\\\n{bitfield_block}{indent * idn})'

            if not args.mix:
                bitfield_block += '\n'

            if args.undef is False:

                if not args.light:
                    assign_block = f'{indent}#if defined {def_name}\n{indent * 2}#if {def_name} != 0\n' \
                        + f'{indent * 3}{reg_name} = {def_name};'.ljust(lj12) + f' {reg_comment}\n{indent * 2}#endif\n'\
                        + f'{indent}#else\n{indent * 2}#define {def_name} 0\n{indent}#endif\n'
                else:
                    assign_block = f'{indent}#if {def_name} != 0\n' \
                        + f'{indent * 2}{reg_name} = {def_name};'.ljust(lj12) + f' {reg_comment}\n{indent}#endif\n'

            else:
                assign_block = f'{indent}#if {def_name} != 0\n{indent * 2}{reg_name} = {def_name};'.ljust(lj12) \
                    + f' {reg_comment}\n{indent}#endif'

        else:
            bitfield_block = f'{indent * idn}#define {def_name} '.ljust(max_field_len[0] + flen) + '0000\n'
            if not args.light:
                assign_block = f'{indent}#if defined {def_name}\n{indent * 2}#if {def_name} != 0\n' \
                    + f'{indent * 3}{reg_name} = {def_name};'.ljust(lj12) + f' {reg_comment}\n{indent * 2}#endif\n' \
                    + f'{indent}#else\n{indent * 2}#define {def_name} 0\n{indent}#endif\n'
            else:
                assign_block = f'{indent}#if {def_name} != 0\n{indent * 2}{reg_name} = {def_name};'.ljust(lj12)\
                             + f' {reg_comment}\n{indent}#endif\n'

        if args.undef is True:
            assign_block += f'\n{indent}#undef {def_name}\n'

    return bitfield_block, assign_block


def make_init_func(func_name, func_body, header='', footer=''):
    hdr = ftr = ''
    if header != '':
        hdr = header + '\n\n'
    if footer != '':
        ftr = '\n\n' + ftr

    return f'__STATIC_INLINE void {func_name}(void) {{\n\n{ftr}{func_body}{hdr}\n}}'


def make_h_module(module_name, module_body):
    mn = module_name.upper()
    return f'#ifndef __{mn}_H__\n#define __{mn}_H__\n\n#ifdef __cplusplus\n  extern "C" {{\n#endif\n\n'\
           + f'{module_body}\n#ifdef __cplusplus\n  }}\n#endif /* __cplusplus */\n' + f'#endif /* __{mn}_H__ */\n'


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
            gs = gy.strip()
            if '' == gs or '//' == gs[:2] or 'AND triple modes' in gs:
                # do not parse empty strings or one's beginning with those
                continue

            while ' ;' in gs:
                gs = gs.replace(' ;', ';')

            w = gs.split()

            p_size = get_reg_size(gs)

            name_ndx = 0

            for gz in range(len(w)):  # find word index of register name
                if w[gz].endswith(';'):
                    name_ndx = gz

            p_name = w[name_ndx][:-1] if gs.startswith('__IO') or gs.startswith('__I') or gs.startswith('__O') \
                else w[1][:-1] if p_size != 'X' else w[1][:-1]

            if p_size == 'X':
                p_size = w[0]

            gc = re.findall(r'/\*\s*(.*?)\s*\*/', gs)
            p_comment = gc[0].lstrip('!').lstrip('<').lstrip() if len(gc) > 0 else ''

            t_list.append([p_name, p_size, p_comment])

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


def strip_suffix(periph_name):
    """ Strip number from peripheral name. Example: 'TIM10' ==> 'TIM' or 'GPIOC' ==> 'GPIO' """
    pn = periph_name
    while True:
        if pn[-1] in '0123456789' or pn[:-1] == 'GPIO':
            pn = pn[:-1]
        else:
            break
    return pn


def find_peripheral(periph_name):
    """ return address and typedef name of the peripheral. Example: ('TIM3', '0x40000400', 'TIM_TypeDef') """
    pn = periph_name.strip()
    for xc in peripheral:
        if args.strict is False:
            if pn in xc[1]:
                yield xc[1], xc[0], xc[2][:-1]
        else:
            if pn == xc[1]:
                yield xc[1], xc[0], xc[2][:-1]


def get_register_set(periph_name):
    pn = strip_suffix(periph_name)
    dict_key = f'{pn}_TypeDef'
    if dict_key in register_dic:
        return register_dic[dict_key]
    return []


def get_register_size(struct_name):
    reg_size = 0
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
    for xa in register_dic[peripheral_property[2]]:
        for reg_name, reg_offs in get_register_property(xa):
            if 'RESERVED' not in reg_name.upper():
                yield [reg_name, xa[2], f'0x{int(peripheral_property[1], 16) + register_address:X}']

            register_address += int(reg_offs)


def get_peripheral_register_list(periph_name):
    for pe in find_peripheral(periph_name):  #
        if is_hex(pe[1]):
            yield pe[0], get_register_list(pe)

    if periph_name == 'USART':
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
    ('RCR',  'C20'), ('CCMR', 'C30'), ('CCER', 'C40'), ('SMCR', 'C50'), ('BDTR', 'U00'),
    ('_SR', '_U10'), ('AHBENR', 'A50'), ('AHB1ENR', 'A51'), ('AHB2ENR', 'A52'), ('AHB3ENR', 'A53'),
    ('APB1ENR', 'A60'), ('APB2ENR', 'A70'), ('LCD_CLR', 'LCD_U20'), ('LCD_RAM_10', 'LCD_RAM_A'),
    ('LCD_RAM_11', 'LCD_RAM_B'), ('LCD_RAM_12', 'LCD_RAM_C'), ('LCD_RAM_13', 'LCD_RAM_D'),
    ('LCD_RAM_14', 'LCD_RAM_E'), ('LCD_RAM_15', 'LCD_RAM_F'), ('LPTIM', 'XTIM'), ('QUADSPI', 'XSPI'),
    ('ADC123', 'ADCT'), ('ADC12', 'ADCU'), ('ADC1_2', 'ADCU'), ('AWD', 'TTD'), ('CALFACT', 'TTF')
]

ini_sort_list = [
    ('LPUART', 'XUART'), ('UART', 'USART'), ('OR', 'ZX1'), ('CCR1', 'CCR0'), ('ISR', 'VV0'),
    ('ICR', 'VV1'), ('RDR', 'WW0'), ('TDR', 'WW1'), ('BRR', 'AAA'), ('PSC', 'AA0'), ('CR1', 'ZZ1'),
    ('EGR', 'AS0'), ('CCER', 'DDER'), ('LPTIM', 'XTIM'), ('LCD_CLR', 'LCD_U20'), ('LCD_CR', 'LCD_XR'),
    ('QUADSPI', 'XSPI'), ('XSPI_CR', 'XSPI_XR'), ('DCR', 'U20'), ('DMAR', 'U40'), ('BDTR', 'U60'),
    ('CR', 'ZZ0'), ('AWD', 'TTD'), ('CALFACT', 'TTF')
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
        n = tim + str(xtr)
        if n in ret_name:
            ret_name = ret_name.replace(n, tim + chr(ord('A') + d1) + chr(ord('A') + d2))

    return ret_name


def sort_ini_block(initialization_block):
    return sort_code_block(initialization_block, ini_sort_list)


def sort_def_block(definition_block):
    return sort_code_block(definition_block, def_sort_list)


if __name__ == '__main__':

    if '-V' in sys.argv or '--version' in sys.argv:
        print('0.08b\n')
        exit()

    import argparse

    parser = argparse.ArgumentParser(prog='stm32cgen', description='STM32 initialization generator')
    parser.add_argument('-V', '--version', action="store_true", help="show version and exit")
    parser.add_argument('cpu', metavar='cpu_name', help='abbreviated MCU name. I.e. "103c8", "g031f6", "h757xi" etc.')
    parser.add_argument('-d', '--direct', action="store_true", default=False, help="No predefined macros")
    parser.add_argument('-D', '--define', nargs='+', help="add #define MACRO at the end")
    parser.add_argument('-H', '--header', nargs='+', help="add strings to header")
    parser.add_argument('-F', '--footer', nargs='+', help="add strings to footer")
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
    parser.add_argument('-m', '--module', help="produce output in form of a header file")
    parser.add_argument('-f', '--function', help="place code into a function")
    parser.add_argument('-p', '--peripheral', nargs='+', help="use specified peripheral(s)")
    parser.add_argument('-r', '--register', nargs='+', help="process the registers specified")
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

    if not s_data:
        print(f'unable to get data for "{args.cpu}"')
        exit()

    tblock = []
    enabler = []
    stout = ''

    code_block_def = []
    code_block_ini = []
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

                if args.undef is False:
                    x_out = '( \\\n' + indent
                    for cnt, ds in enumerate(sorted(def_set), start=1):
                        x_out += f'({ds} != 0) || '
                        if cnt % 5 == 0:
                            x_out += '\\\n' + indent

                    if len(def_set) % 5 == 0:
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

                def_set = set()

            if len(enabler) != 0 and args.function:
                x_out = ''
                for cnt, en in enumerate(sorted(enabler), start=1):
                    x_out += f'({en} != 0) || '
                    if cnt % 5 == 0:
                        x_out += f'\\\n{indent * 3}'

                x_out = f'#if 0\n{indent}#if {x_out[:-3]}\n{indent * 2}{args.function}();\n{indent}#endif\n#endif\n'
                tblock.append(x_out)

        def_block = init_block = ''

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

        if args.function:
            stout = f'{def_block}\n\n\n{make_init_func(args.function, init_block)}'.strip('\n')
        else:
            stout = f'{def_block}\n\n{init_block}'

        if args.header:
            x_out = ''
            for x_hdr in args.header:
                x_out += x_hdr + '\n'
            stout = x_out + stout

        stout = f'/* This code is intended to run on {args.cpu} microcontroller. ' + \
                f'Created using stm32cgen. */\n\n{stout.strip()}'

        # delete all '#if 0' strings from the list except the last
        tb = [st for st in tblock if st.startswith('#if 0')]
        if len(tb) > 1:
            tblock = [st for st in tblock if '#if 0' not in st] + [tb[-1]]

        stout += '\n\n'
        if not args.direct:
            for en in tblock:
                stout += en + '\n'

        if args.define:
            ndx = 0
            stout += '\n'
            while len(args.define) > ndx:
                stout += '#define ' + args.define[ndx]
                ndx += 1
                if ndx == len(args.define):
                    break
                stout += indent * 4 + args.define[ndx] + '\n'
                ndx += 1

        if args.footer:
            x_out = ''
            for x_hdr in args.footer:
                x_out += x_hdr + '\n'
            stout = stout + x_out

        if args.module:
            stout = make_h_module(args.module, stout)

        print(stout)

    if len(sys.argv) < 4 and args.cpu != '':
        for x in peripheral:
            print(x[1].ljust(15), x[0], x[2][:-1], '"' + x[3] + '"')

        print()

        print(f'Peripheral count: {len(peripheral)} (uniq address: {len(uniq_addr)});')
        print(f'Unique type count: {len(uniq_type)} (from {len(defined_type)} defined);')
        print(f'Extra: {len(list(set(defined_type) - set(uniq_type)))} {list(set(defined_type) - set(uniq_type))}')
