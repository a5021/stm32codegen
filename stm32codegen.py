#!/usr/bin/env python

import re
import sys

try:
    from stm32cmsis import read_cmsis_header_file
except ImportError:
    print('Could not import CMSIS library')
    # print('pip install cmsis')
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

reg_init = 'indirect'
undef_req = 'no'
ident = 2 * ' '


def get_cmsis_header_file(hdr_name):
    txt, hf_name = read_cmsis_header_file(hdr_name)
    if not txt:
        return "", ""

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

    return txt, hf_name


def get_peripheral_description(src):
    m = re.findall(r'Peripheral_registers_structures(.*?)Peripheral_memory_map', src, re.MULTILINE | re.DOTALL)
    n = re.findall(r'(.*?)\s*}\s*(\w*?TypeDef);', m[0], re.MULTILINE | re.DOTALL)
    for ix in n:
        pg = re.findall(r'/\*\*[^*].*?@brief\s*(.*?)\s*\*/', ix[0], re.MULTILINE | re.DOTALL)
        yield ix[1], pg[0] if pg else ""


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
                            lx[3] = 'Filter Math ACcelerator'
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
            lx[1] = re.sub(r'([0-9a-fA-F])(?:[UL])|(?:[L])', '\\1', lx[1], 0)  # strip suffixes: '0x1FUL' --> '0x1F'

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

            if gx[0][-2] == '_' and gx[0][-1] in '0123456789':  # if string ends with _1 or _2 or _3 etc.
                gx[2] = '  ' + gx[2].strip()

            yield gx


def get_init_block(src, target):
    global macro_definition

    if not macro_definition:
        macro_definition = parse_macro_def(src)

    for lx in target:

        r_name = lx.upper().split('->')

        r_name[0] = strip_suffix(r_name[0])

        if 'AFR[0]' == r_name[1]:
            r_name[1] = 'AFRL'
        elif 'AFR[1]' == r_name[1]:
            r_name[1] = 'AFRH'

        if (args.cpu[0] == '3' or args.cpu[0:2] == 'L0' or args.cpu[0:2] == 'L1') and r_name[1] == 'OSPEEDR':
            r_name[1] = 'OSPEEDER'

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


def is_direct_init_mode():
    return reg_init.upper() == 'DIRECT'


def compose_reg_init(reg_name, bit_def, comment=''):
    out_str = ''
    for lx in bit_def:
        cn = '|  /* '
        if lx == bit_def[-1]:
            cn = ' ' + cn[1:]
        out_str += ident * 2 + '0 * ' + lx[0].ljust(max_field_len[0] + 1) + cn + lx[1].ljust(max_field_len[1] + 2) \
            + lx[2].ljust(max_field_len[2] + 1) + lx[3].ljust(11) + ' */'

        if is_direct_init_mode():
            out_str += '\n'
        else:
            out_str += '\\\n'

    if is_direct_init_mode():
        if out_str != '':
            out_str = ident + reg_name + ' = (\n' + out_str + ident + ');'
        else:
            out_str = ident + reg_name + ' = 0000;'

    else:
        rg_name = reg_name.replace("->", "_").replace('[', '_').replace(']', '')
        if out_str != '':
            out_str = f'{ident}#define {rg_name} ('.ljust(max_field_len[0] + 9) \
                      + '\\\n' + out_str + ident + ')\n' + ident + '#if ' + rg_name + ' != 0\n' \
                      + ident * 2 + reg_name + ' = ' + rg_name + ';\n' + ident + '#endif'
        else:
            out_str = f'{ident}#define {rg_name} '.ljust(max_field_len[0] + 9) + '0000\n' + ident \
                      + '#if ' + rg_name + ' != 0\n' \
                      + ident * 2 + reg_name + ' = ' + rg_name + ';\n' + ident + '#endif'

        if undef_req.upper() == 'YES':
            out_str += '\n' + ident + '#undef ' + rg_name

    return out_str


def make_init_func(func_name, func_body):
    return f'\n__STATIC_INLINE void {func_name}(void) {{\n\n{func_body}}}'


def make_init_module(module_name, module_body):
    uname = module_name.upper()
    return f'#ifndef __{uname}_H__\n#define __{uname}_H__\n\n' \
           + '#ifdef __cplusplus\n  extern "C" {\n#endif\n\n' + module_body + '\n\n#ifdef __cplusplus\n  }\n' \
           + '#endif /* __cplusplus */\n' + f'#endif /* __{uname}_H__ */\n'


def compose_init_block(src, reg_set, comment=''):
    fx = list(get_init_block(src, reg_set))
    out_str = ''
    for lx in range(len(fx)):
        out_str += compose_reg_init(reg_set[lx], fx[lx]) + '\n' * 2

    return out_str


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
            if '' == gs or '//' == gs[:2]:
                # do not parse empty strings or ones beginning with '//'
                continue

            w = gs.split()

            p_size = get_reg_size(gs)

            name_ndx = 0

            for gz in range(len(w)):        # find word index of register name
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
        if pn in xc[1]:
            yield xc[1], xc[0], xc[2][:-1]


'''
def find_peripheral_type(periph_name):
    pn = strip_suffix(periph_name)

    for xf in peripheral:
        if xf[1] == pn:
            return xf[2][:-1]

    return ""
'''


def get_register_set(periph_name):
    pn = strip_suffix(periph_name)
    dict_key = pn + '_TypeDef'
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
        for ndx in range(int(arr_size)):
            yield reg_name[0][:left_bracket + 1] + str(ndx) + ']', get_register_size(reg_name[1])
    else:
        yield reg_name[0], get_register_size(reg_name[1])


def get_register_list(peripheral_property):
    register_address = 0
    for xa in register_dic[peripheral_property[2]]:
        for reg_name, reg_offs in get_register_property(xa):
            if 'RESERVED' not in reg_name.upper():
                yield [reg_name, xa[2],  f'0x{int(peripheral_property[1], 16) + register_address:X}']

            register_address += int(reg_offs)


def get_peripheral_register_list(periph_name):
    for pe in find_peripheral(periph_name):  #
        if is_hex(pe[1]):
            yield pe[0], get_register_list(pe)


if __name__ == '__main__':

    import argparse

    parser = argparse.ArgumentParser(prog='stm32cmsis', description='STM32 initialization generator')
    parser.add_argument('cpu', metavar='cpu_name', help='abbreviated MCU name. I.e. "103c8", "g031f6", "h757xi" etc.')
    # parser.add_argument('-a', '--all', action="store_true", default=False)
    parser.add_argument('-d', '--direct', action="store_true", default=False, help="No predefined macros")
    parser.add_argument('-n', '--no-undef', action="store_true", default=False, help="No undef")
    parser.add_argument('-s', '--separate-func', action="store_true", default=False)
    parser.add_argument('-S', '--separate-module', action="store_true", default=False)
    parser.add_argument('--save-header-file', action="store_true", default=False)
    parser.add_argument('-i', '--ident', type=int, default=2)
    parser.add_argument('-m', '--module', nargs='+')
    parser.add_argument('-f', '--function', nargs='+')
    parser.add_argument('-p', '--peripheral', nargs='+')
    parser.add_argument('-r', '--register', nargs='+')
    # parser.add_argument('-m', '--module', action='append', nargs='+')
    # parser.add_argument('-f', '--function',  action='append', nargs='+')
    # parser.add_argument('-p', '--peripheral', action='append', nargs='+')
    # parser.add_argument('-r', '--register', action='append', nargs='+')

    args = parser.parse_args()

    if args.direct:
        reg_init = 'direct'

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

    print('Parameters passed', len(sys.argv))

    # print(len(args))

    '''
    with open(CMSIS_header_file, 'r') as f:
        s_data = f.read()
    '''

    # s_data = read_cmsis_header_file("205rc")
    # s_data = read_cmsis_header_file("429ig")
    # s_data = read_cmsis_header_file("h743zi")
    # s_data = read_cmsis_header_file("303c8")
    # s_data = get_cmsis_header_file("l496zg")
    # s_data = get_cmsis_header_file("g474re")

    print(args)

    s_data, hdr_file_name = get_cmsis_header_file(args.cpu)

    if not s_data:
        print(f'unable to get data for "{args.cpu}"')
        exit()

    if args.save_header_file:
        with open(hdr_file_name, 'bw') as f:
            f.write(bytes(s_data, 'utf-8'))

    # print(peripheral)
    # exit()

    '''
    for key, value in register_dic.items():
        print(key)
        for x in value:
            # print('  name =', x[0] + '; size =', x[1] + '; desc = "' + x[2] + '"')
            print(' ', x)

    print()
    '''

    # print(peripheral[6][2][:-1])

    if args.peripheral:
        for p in args.peripheral:
            for name, lst in get_peripheral_register_list(p):
                # print(name, ':')
                for xp in lst:
                    print(compose_init_block(s_data, [name + '->' + xp[0]]))
                    # print(xp)

    '''
    for z in g:
        defined_type.append()
    '''

    if len(sys.argv) == 2 and args.cpu != '':
        for x in peripheral:
            print(x[1].ljust(15), x[0], x[2][:-1], '"' + x[3] + '"')

        print()

        print(f'Peripheral count: {len(peripheral)} (uniq address: {len(uniq_addr)});')
        print(f'Unique type count: {len(uniq_type)} (from {len(defined_type)} defined);')
        print(f'Extra: {len(list(set(defined_type) - set(uniq_type)))} {list(set(defined_type) - set(uniq_type))}')

    # target = 'RCC_CFGR_'
    # target = 'RCC_APB2ENR_'
    # target = 'TIM5->CR1'
    # target = 'I2C_SR'
    # target = 'GPIO_CRL'
    # target = 'TIM10->EGR'

    # init_section = ['TIM5->PSC', 'TIM5->ARR', 'TIM5->EGR', 'TIM5->SR', 'TIM5->CR2', 'TIM5->DIER', 'TIM5->CR1']

    # print(peripheral)
    # exit()

    per = reg = []

    if args.register:
        if 'ALL' == args.register[0][0].upper():
            reg = []
        else:
            reg = args.register

    if args.peripheral:
        if 'ALL' == args.peripheral[0][0].upper():
            per = [x[1] for x in peripheral]
        else:
            per = args.peripheral

    # print(per)
    # print(g)
    exit()

    x_reg = [x + '->' + y for x in per for y in reg]
    s = compose_init_block(s_data, x_reg)

    if args.function:
        s = make_init_func(args.function, s)

    if args.module:
        s = make_init_module(args.module, s)

    print(s)

    # for x in args.register:
    #   x_reg.append(args.peripheral[0] + '->' + x)

    # print(x_reg)
    # exit()

    if False:

        tim1 = ['TIM1->PSC', 'TIM1->ARR', 'TIM1->EGR', 'TIM1->SR', 'TIM1->CCMR1', 'TIM1->CCMR2', 'TIM1->CCER',
                'TIM1->CR2', 'TIM1->BDTR', 'TIM1->CR1']
        tim2 = ['TIM2->PSC', 'TIM2->ARR', 'TIM2->EGR', 'TIM2->SR', 'TIM2->CR1']
        i2c1 = ['I2C1->CR2', 'I2C1->CCR', 'I2C1->TRISE', 'I2C1->CR1']
        usart1 = ['USART1->BRR', 'USART1->CR3', 'USART1->CR2', 'USART1->CR1']

        # fx = get_init_block(s_data, reg)
        # for x in range(len(fx)):
        #     print(compose_reg_init(reg[x], fx[x]))
        #     print()

        print()
        print(
            make_init_module("timer",
                             make_init_func("tim_1",
                                            compose_init_block(s_data, tim1)
                                            ) + '\n\n' +
                             make_init_func("tim_2",
                                            compose_init_block(s_data, tim2)
                                            )
                             )
        )
        print(
            make_init_module("i2c",
                             make_init_func("i2c1",
                                            compose_init_block(s_data, i2c1)
                                            )
                             )
        )

        print(
            make_init_module("usart",
                             make_init_func("usart1",
                                            compose_init_block(s_data, usart1)
                                            )
                             )
        )


'''
    # for x in fx:
    #     for y in x:
    #         print(y)
    #     print()

        # for y in x[1]:
        #    #print(y)
        #    pass

    # print(compose_init_block(s_data, x), end='\n\n')
    # print(compose_init_block(s_data, 'TIM5->CR2'))
    # print(compose_init_block(s_data, 'TIM5->DIER'))
    # print(get_init_block(s_data, target))
'''
