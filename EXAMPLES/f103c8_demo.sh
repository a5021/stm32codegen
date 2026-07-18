#!/bin/bash

set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Safer field splitting

ORIGINAL_DIR="$(pwd)"

# === Error Handling ===
cleanup() {
    local exit_code=$?
    
    # Capture ERR context if available
    if [[ ${__err_line:-} ]]; then
        echo "ERROR at line $__err_line: $__err_command failed" >&2
    fi
    
    if [ $exit_code -ne 0 ]; then
        echo "" >&2
        echo "====================================" >&2
        echo "Script failed - returning to $ORIGINAL_DIR" >&2
        echo "====================================" >&2
    fi
    
    cd "$ORIGINAL_DIR" 2>/dev/null || true
    exit $exit_code
}

# Store ERR context for cleanup
trap '__err_line=$LINENO; __err_command=$BASH_COMMAND' ERR
trap cleanup EXIT

VERBOSE="${VERBOSE:-0}"
DEBUG="${DEBUG:-0}"

[ "$VERBOSE" = "1" ] && set -x

cd "$(dirname "${BASH_SOURCE[0]}")"

base_dir=$(basename "$0" .sh)

# Array with directory names
directories=("inc" "src" "MDK-ARM")
op_counter=0

check_dependencies() {
    local missing=()
    
    for cmd in curl arm-none-eabi-gcc base64 xz make; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required tools: ${missing[*]}" >&2
        echo "" >&2
        echo "Installation instructions:" >&2
        echo "  Debian/Ubuntu: sudo apt-get install ${missing[*]}" >&2
        echo "  Red Hat/CentOS: sudo yum install ${missing[*]}" >&2
        exit 1
    fi
}

press_any_key() {
    echo -n "Press any key to continue..."
    # read one character of input and discard it
    read -n 1 -s -r || true
    echo ""
}

check_dependencies

# Function to check for the existence of a directory and create it if it doesn't exist
create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        if mkdir "$dir"; then
            ((++op_counter))
            echo "Directory $dir created."
        else
            echo "Error: Failed to create directory $dir" >&2
            exit 1
        fi
    fi
}

# Create directories
create_directory "$base_dir" && cd "$base_dir"

for dir in "${directories[@]}"
do
  create_directory "$dir"
done

cd "${directories[0]}"

PY_GEN="$(realpath "${PY_GEN:-../../..}")"

if [ -e stm32f103xb.h ]; then
    # File exists
    opt=-l
else
    # File does not exist
    opt=-s
fi

py_name=''

# Detect Python
case $(uname -s | tr '[:upper:]' '[:lower:]') in
    linux*|darwin*)  py_name='python3' ;;
    *)               py_name='python' ;;  # Windows and others
esac

# Verify Python works
if ! command -v "$py_name" &>/dev/null; then
    echo "Error: $py_name not found" >&2
    exit 1
fi

force_inline=--force-inline
func_name=init_systick
PY_GEN_PY="$PY_GEN"
if command -v cygpath &>/dev/null; then
    py_path="$(command -v "$py_name")"
    case "$py_path" in
        /usr/bin/*|/bin/*) ;;  # Cygwin Python вЂ” keep cygwin path
        *) PY_GEN_PY="$(cygpath -w "$PY_GEN")" ;;  # Windows Python вЂ” convert
    esac
fi
py_gen=("$py_name" "$PY_GEN_PY/stm32cgen.py")

# Validate stm32cgen.py exists and is readable
if [ ! -f "$PY_GEN/stm32cgen.py" ]; then
    echo "Error: stm32cgen.py not found at $PY_GEN" >&2
    echo "Current PY_GEN=$PY_GEN" >&2
    exit 1
fi

generate_header() {
    local output_file="$1"
    shift  # Remove first argument
    
    if "${py_gen[@]}" "$@" > "$output_file"; then
        echo "File $output_file created."
        ((++op_counter))
    else
        echo "Error: Failed to generate $output_file" >&2
        exit 1
    fi
}

generate_header "main.h" $opt 103c8 -M\
    -D NO                     0\
       NONE                   NO\
       OFF                    NO\
       YES                    \(\!NO\)\
       ON                     YES\
       ""\
        HCLK                   "8    /* 8 to 72 (MHz) with a step of 4 */"\
        ""\
        SYSTICK_CLOCK_SOURCE   "0    /* 0 = HCLK / 8; 1 = HCLK         */"\
        SYSTICK_ENABLE         YES\
        SYSTICK_IRQ_ENABLE     NO\
     \
     -H "#if HCLK < 8 || HCLK > 72 || (HCLK % 4 != 0)"\
     -H "  #error \"Invalid HCLK value. Must be between 8 and 72 MHz with a step of 4 MHz.\""\
     -H \#endif\
    \
    $force_inline\
    --post-init $func_name\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F ""\
    -F "  /* Initialize SysTick to 1 ms period */"\
    -F ""\
    -F "  SysTick->LOAD = HCLK * 1000 / (8 - SYSTICK_CLOCK_SOURCE * 7) - 1;"\
    -F "  SysTick->VAL  = SysTick->LOAD;"\
    -F "  SysTick->CTRL = ("\
    -F "    + SYSTICK_CLOCK_SOURCE * SysTick_CTRL_CLKSOURCE_Msk"\
    -F "    + SYSTICK_IRQ_ENABLE   * SysTick_CTRL_TICKINT_Msk"\
    -F "    + SYSTICK_ENABLE       * SysTick_CTRL_ENABLE_Msk"\
    -F "  );"\
    -F "} /* $func_name() */"\
    -F ""\
    -F ""\
    -F "__STATIC_FORCEINLINE void idle(void); // {"\
    -F "  /* Routine to handle idle state (waiting for an event) */"\
    -F ""\
    -F ""\
    -F "//} /* idle() */"\
    -F ""\
    -F ""\
    -F "__STATIC_FORCEINLINE unsigned process(void); // {"\
    -F "  /* Routine to perform main loop operations */"\
    -F ""\
    -F ""\
    -F "//} /* process() */"\
    -F ""\
    -F "#if YES == SYSTICK_IRQ_ENABLE"\
    -F "  #define __SYSTICK_VOLATILE volatile"\
    -F "#else"\
    -F "  #define __SYSTICK_VOLATILE"\
    -F "#endif"\
    -F ""\
    -F "#if defined(__GNUC__) && ! defined(__clang__)" \
    -F "  void _close_r(void){} void _close(void){} void _lseek_r(void){} void _lseek(void){} void _read_r(void){} void _read(void){} void _write_r(void){}" \
    -F \#endif

func_name=wait_for_clock_stable
tag=R
generate_header "rcc.h" -l 103c8 -p RCC -m rcc -f init_rcc\
    \
    -D $tag '(HCLK >= 16)'\
       XMUL "(HCLK / 8 - 2)     /* PLL multiplication: HCLK = 8MHz HSE * (XMUL + 2) */"\
       A    "((XMUL >> 0) & 1)  /* LSB or BIT0 of PLL multiplication factor */"\
       B    "((XMUL >> 1) & 1)  /*        BIT1 of PLL multiplication factor */"\
       C    "((XMUL >> 2) & 1)  /*        BIT2 of PLL multiplication factor */"\
       D    "((XMUL >> 3) & 1)  /* MSB or BIT3 of PLL multiplication factor */"\
    \
    --tag-bit R SW_PLL PLLON HSION HSITRIM_4\
    --tag-bit A PLLMULL0\
    --tag-bit B PLLMULL1\
    --tag-bit C PLLMULL2\
    --tag-bit D PLLMULL3\
    \
    $force_inline\
    --pre-init configure_flash\
    --post-init $func_name\
    -F "__STATIC_FORCEINLINE void configure_flash(void) {"\
    -F "  #if (HCLK > 24)"\
    -F "    /* Configure flash to use 1 wait state and enable prefetch buffer */"\
    -F "    FLASH->ACR = FLASH_ACR_LATENCY | FLASH_ACR_PRFTBE;"\
    -F "  #endif"\
    -F "}"\
    -F ""\
    -F "__STATIC_FORCEINLINE void $func_name(void) {"\
    -F "  #if $tag"\
    -F "    while(RCC_CFGR_SWS_PLL != (RCC->CFGR & RCC_CFGR_SWS_PLL)) {}"\
    -F "  #endif"\
    -F "} /* $func_name() */"\
    -F ""\
    -F "#undef A"\
    -F "#undef B"\
    -F "#undef C"\
    -F "#undef D"\
    -F "#undef $tag"

# GPIO pin configuration header (BluePill_Project_Generator style).
# Replaces the stm32cgen-generated gpio.h: the macros and the init logic
# are copied verbatim from https://github.com/a5021/BluePill_Project_Generator
# so the example uses the same proven, reviewed GPIO handling as that project.
cat > "gpio.h" << 'EOF'
#ifndef __GPIO_H__
#define __GPIO_H__

#include <stdint.h>
#include "stm32f103xb.h"

/* ------------------------------------------------------------------ */
/* Pin configuration field builder (4-bit field: CNF[1:0] + MODE[1:0]) */
/* Source: BluePill_Project_Generator (create_stm32f1_project)        */
/* ------------------------------------------------------------------ */
#define PIN_CFG(PIN, MODE)              ((MODE) << ((PIN) * 4))

/* Input mode (MODE[1:0] = 00) */
#define I_ANALOG                        (0ULL << 2)   /* Analog mode                  */
#define I_FLOAT                         (1ULL << 2)   /* Floating input               */
#define I_PULL                          (2ULL << 2)   /* Input with pull-up / down    */

/* Output mode (MODE[1:0] > 00) */
#define O_PP                            (0ULL << 2)   /* General purpose push-pull    */
#define O_OD                            (1ULL << 2)   /* General purpose open-drain   */
#define O_AF                            (2ULL << 2)   /* Alternate function            */

/* MODE[1:0]: output speed */
#define O_10MHZ                         1ULL          /* Max speed 10 MHz             */
#define O_2MHZ                          2ULL          /* Max speed 2 MHz              */
#define O_50MHZ                         3ULL          /* Max speed 50 MHz             */

/* BSRR bit masks */
#define _BR(PIN)                        GPIO_BSRR_BR ## PIN
#define _BS(PIN)                        GPIO_BSRR_BS ## PIN
#define BR(PIN)                         _BR(PIN)
#define BS(PIN)                         _BS(PIN)
#define PIN_HIGH(PIN)                   GPIO_BSRR_BS ## PIN
#define PIN_LOW(PIN)                    GPIO_BSRR_BR ## PIN
#define PULL_UP(PIN)                    GPIO_BSRR_BS ## PIN
#define PULL_DOWN(PIN)                  GPIO_BSRR_BR ## PIN

/* ------------------------------------------------------------------ */
/* Port C: on-board LED on PC13 (Blue Pill, active-low)               */
/* ------------------------------------------------------------------ */
#define PORT_C_CONFIG   PIN_CFG(13, O_2MHZ)          /* PC13: output, push-pull, 2 MHz */
#define PORT_C_STATE    PIN_HIGH(13)                 /* PC13 HIGH = LED off            */
#define IOPC_EN         (PORT_C_CONFIG != 0)

__STATIC_FORCEINLINE void init_gpio(void) {
#if defined GPIOC_BASE
  /* State (pull/level) first, then CRL/CRH (mode) */
  if (PORT_C_STATE) GPIOC->BSRR = (uint32_t)PORT_C_STATE;
  *(__IO uint64_t *)GPIOC_BASE = (uint64_t)PORT_C_CONFIG;
#endif
}

#endif /* __GPIO_H__ */
EOF
echo "File gpio.h created."
((++op_counter))


cd ..

create_file() {
    local filename="$1"
    
    if [ ! -f "$filename" ]; then
        if base64 -d | xz -qdc > "$filename"; then
            if [ -s "$filename" ]; then  # Check file is not empty
                ((++op_counter))
                echo "File $filename created."
            else
                echo "Error: $filename is empty after creation" >&2
                rm -f "$filename"
                return 1
            fi
        else
            echo "Error: Failed to decode/decompress $filename" >&2
            return 1
        fi
    fi
}

# Base64-encoded xz-compressed Makefile (generated with: cat Makefile | xz -9c | base64)
create_file "Makefile" << 'EOF'
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
EOF

create_file "stm32f103xb_flash.ld" << 'EOF'
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4A8NBIpdABeKgCRDWZigxFgAKUhK1Ev7lGpI9l8XUoFV5/QHJi6P4/TdOYJw3WwqJ3YkQNxliitnsSeWQRVTcXAeaRrSbZuvr1yyI6JOM6SBLRq5rX68Himl7Dw69JMmTCKn3g7UAQpOuI0wOZBBGyIOktyFNOUAfT3MoUEGc4Sbvh6rScR5iHXtHvpaSsNcMTSyrg9nTyXmb4boMIsd0afdV0/rXGPX6M4Z7STaEbgOUcNFnt0+w959DsmhPgIdz7Vay5s8qh7I2hV3Kz6zrcqN6BKT58DUnE9cjrSDFVV22n2j9kzLR/0dTGxPFV3HHCHKFzhccLYQNTggriO8bxKa/UOwFTzYIvIVOWivVee7py8DeqcmjfrUzCqusAieeeSa0JMmqHw6ie56bz16gwQhP/QGXapkPtoUeOUHi8hJcR8A7URnD2fDqcWVASw+Eqvo2iuMBazqZpMXWVIzkFom/hNJkJZRRLiWdz02uRHm0A2gmfqyECey8ewmrtvh9nIYwlh2Nvgo/zBpcl2xYdfdS2sLnuarf6MEqcILwxb/CoxXPTtloB884pt3EFgtPXtj3TlpXkXdp5TZ4OEsF8BtFx/IL4hSueaS+zmJEZPIFPtFCfK8ai6oXuA/va+26rOiMm70RpknyFz7ITRZyJSf+iSoTpt1VEALW7vsSfO65UrX8kN/qRrxxjlDErx1hLw1a5L1m/1NCPggCE+Nazh4ufrfVMU6+/96Iqzg5VzdAfN7Pqv1/sr5bvZ6N4vKfb+64PLHZf2xx2nKfSUDCdRW7r8sVeJU8LGFB/ygTtDcDaViLXkYhty1zWkY2BEUV0A9WXYB/K5u8AsFNUoajiEKWhKFHnwlZ7lNOagmFoUhpLGp85vVkgzpv9UUaaFnJ62uLH8ZivVDYqge/kBdMWYO4Szq2N6q3oEUTyVYJybIy+HRfABVxJMe2JTa1cPCgWdtzyGWG1mFY3wDT5X3BGcFnuF7DsWXnyCKESxToneXyeKSzlSqla4mlsudZJLOT8vhfIsqe7rTWjDiicNtO7X1b+QQaZqd1K9DpV17QLsfXSse5QBATp6AqQZdpW0OhNL/l9mythii5ph9JFIwns/Q+UFDs/bGAxO++6RgALZDSDpS7zLyMXGqIjNhTaqsF7EEvrm1K+WI2a+QTXLUbHZ8eXe0iQ0UObikrhKGuCv4QOm1b87IpWN97kFQLwsjssuYISKij2RTXKdILgiLC4T6nYCx370V+3O5RROL/vpBWvImOECzrSQWBCEOpyAm+qHqpZK8/oVZmAptEMHlFpr5UzYKO5NSBx+lkc8z6VbnQ5qSmpywzXjx9xxsBodhZO00Sfn+iZLHE6uYen+PnoJVfC9tsp7TmtpEcDdTTtxo6Q5yj5iKaTlkrxS4O9zady1nRLSy5c/U8kAxwsIpatQu+Tk7KU+dZreANDFEZVt3Ib6eyxS6mKfv1W1MwKRiriuu5MBlaeV0PmW7K0acJste/saemeyp7KGzGOWWq6Sxrg9b0wJ3n1i4vciNsAa3y/31XNpC+4nIf9OEWcOgzSAAAACO8oDZLul0PAABpgmOHgAALQs+GrHEZ/sCAAAAAARZWg==
EOF

cat > "MDK-ARM/Project.uvprojx" << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<Project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="project_projx.xsd">

  <SchemaVersion>2.1</SchemaVersion>

  <Header>### uVision Project, (C) Keil Software</Header>

  <Targets>
    <Target>
      <TargetName>Debug</TargetName>
      <ToolsetNumber>0x4</ToolsetNumber>
      <ToolsetName>ARM-ADS</ToolsetName>
      <uAC6>1</uAC6>
      <TargetOption>
        <TargetCommonOption>
          <Device>STM32F103CB</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00001000) IROM(0x08000000,0x00004000) CPUTYPE("Cortex-M3") CLOCK(8000000) ELITTLE</Cpu>
          <FlashUtilSpec></FlashUtilSpec>
          <StartupFile></StartupFile>
          <FlashDriverDll></FlashDriverDll>
          <DeviceId></DeviceId>
          <RegisterFile></RegisterFile>
          <MemoryEnv></MemoryEnv>
          <Cmp></Cmp>
          <Asm></Asm>
          <Linker></Linker>
          <OHString></OHString>
          <InfinionOptionDll></InfinionOptionDll>
          <SLE66CMisc></SLE66CMisc>
          <SLE66AMisc></SLE66AMisc>
          <SLE66LinkerMisc></SLE66LinkerMisc>
          <SFDFile>..\STM32F103xx.svd</SFDFile>
          <bCustSvd>0</bCustSvd>
          <UseEnv>0</UseEnv>
          <BinPath></BinPath>
          <IncludePath></IncludePath>
          <LibPath></LibPath>
          <RegisterFilePath></RegisterFilePath>
          <DBRegisterFilePath></DBRegisterFilePath>
          <TargetStatus>
            <Error>0</Error>
            <ExitCodeStop>0</ExitCodeStop>
            <ButtonStop>0</ButtonStop>
            <NotGenerated>0</NotGenerated>
            <InvalidFlash>1</InvalidFlash>
          </TargetStatus>
          <OutputDirectory>.\Objects\</OutputDirectory>
          <OutputName>Project</OutputName>
          <CreateExecutable>1</CreateExecutable>
          <CreateLib>0</CreateLib>
          <CreateHexFile>1</CreateHexFile>
          <DebugInformation>1</DebugInformation>
          <BrowseInformation>1</BrowseInformation>
          <ListingPath>.\Listings\</ListingPath>
          <HexFormatSelection>1</HexFormatSelection>
          <Merge32K>0</Merge32K>
          <CreateBatchFile>0</CreateBatchFile>
          <BeforeCompile>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopU1X>0</nStopU1X>
            <nStopU2X>0</nStopU2X>
          </BeforeCompile>
          <BeforeMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopB1X>0</nStopB1X>
            <nStopB2X>0</nStopB2X>
          </BeforeMake>
          <AfterMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopA1X>0</nStopA1X>
            <nStopA2X>0</nStopA2X>
          </AfterMake>
          <SelectedForBatchBuild>0</SelectedForBatchBuild>
          <SVCSIdString></SVCSIdString>
        </TargetCommonOption>
        <CommonProperty>
          <UseCPPCompiler>0</UseCPPCompiler>
          <RVCTCodeConst>0</RVCTCodeConst>
          <RVCTZI>0</RVCTZI>
          <RVCTOtherData>0</RVCTOtherData>
          <ModuleSelection>0</ModuleSelection>
          <IncludeInBuild>1</IncludeInBuild>
          <AlwaysBuild>0</AlwaysBuild>
          <GenerateAssemblyFile>0</GenerateAssemblyFile>
          <AssembleAssemblyFile>0</AssembleAssemblyFile>
          <PublicsOnly>0</PublicsOnly>
          <StopOnExitCode>3</StopOnExitCode>
          <CustomArgument></CustomArgument>
          <IncludeLibraryModules></IncludeLibraryModules>
          <ComprImg>1</ComprImg>
        </CommonProperty>
        <DllOption>
          <SimDllName>SARMCM3.DLL</SimDllName>
          <SimDllArguments> -REMAP </SimDllArguments>
          <SimDlgDll>DARMCM1.DLL</SimDlgDll>
          <SimDlgDllArguments>-pCM0</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM0</TargetDlgDllArguments>
        </DllOption>
        <DebugOption>
          <OPTHX>
            <HexSelection>1</HexSelection>
            <HexRangeLowAddress>0</HexRangeLowAddress>
            <HexRangeHighAddress>0</HexRangeHighAddress>
            <HexOffset>0</HexOffset>
            <Oh166RecLen>16</Oh166RecLen>
          </OPTHX>
        </DebugOption>
        <Utilities>
          <Flash1>
            <UseTargetDll>1</UseTargetDll>
            <UseExternalTool>0</UseExternalTool>
            <RunIndependent>0</RunIndependent>
            <UpdateFlashBeforeDebugging>1</UpdateFlashBeforeDebugging>
            <Capability>1</Capability>
            <DriverSelection>4096</DriverSelection>
          </Flash1>
          <bUseTDR>1</bUseTDR>
          <Flash2>BIN\UL2CM3.DLL</Flash2>
          <Flash3></Flash3>
          <Flash4></Flash4>
          <pFcarmOut></pFcarmOut>
          <pFcarmGrp></pFcarmGrp>
          <pFcArmRoot></pFcArmRoot>
          <FcArmLst>0</FcArmLst>
        </Utilities>
        <TargetArmAds>
          <ArmAdsMisc>
            <GenerateListings>0</GenerateListings>
            <asHll>1</asHll>
            <asAsm>1</asAsm>
            <asMacX>1</asMacX>
            <asSyms>1</asSyms>
            <asFals>1</asFals>
            <asDbgD>1</asDbgD>
            <asForm>1</asForm>
            <ldLst>0</ldLst>
            <ldmm>1</ldmm>
            <ldXref>1</ldXref>
            <BigEnd>0</BigEnd>
            <AdsALst>1</AdsALst>
            <AdsACrf>1</AdsACrf>
            <AdsANop>0</AdsANop>
            <AdsANot>0</AdsANot>
            <AdsLLst>1</AdsLLst>
            <AdsLmap>1</AdsLmap>
            <AdsLcgr>1</AdsLcgr>
            <AdsLsym>1</AdsLsym>
            <AdsLszi>1</AdsLszi>
            <AdsLtoi>1</AdsLtoi>
            <AdsLsun>1</AdsLsun>
            <AdsLven>1</AdsLven>
            <AdsLsxf>1</AdsLsxf>
            <RvctClst>0</RvctClst>
            <GenPPlst>0</GenPPlst>
            <AdsCpuType>"Cortex-M3"</AdsCpuType>
            <RvctDeviceName></RvctDeviceName>
            <mOS>0</mOS>
            <uocRom>0</uocRom>
            <uocRam>0</uocRam>
            <hadIROM>1</hadIROM>
            <hadIRAM>1</hadIRAM>
            <hadXRAM>0</hadXRAM>
            <uocXRam>0</uocXRam>
            <RvdsVP>0</RvdsVP>
            <RvdsMve>0</RvdsMve>
            <RvdsCdeCp>0</RvdsCdeCp>
            <hadIRAM2>0</hadIRAM2>
            <hadIROM2>0</hadIROM2>
            <StupSel>8</StupSel>
            <useUlib>1</useUlib>
            <EndSel>0</EndSel>
            <uLtcg>0</uLtcg>
            <nSecure>0</nSecure>
            <RoSelD>3</RoSelD>
            <RwSelD>3</RwSelD>
            <CodeSel>0</CodeSel>
            <OptFeed>0</OptFeed>
            <NoZi1>0</NoZi1>
            <NoZi2>0</NoZi2>
            <NoZi3>0</NoZi3>
            <NoZi4>0</NoZi4>
            <NoZi5>0</NoZi5>
            <Ro1Chk>0</Ro1Chk>
            <Ro2Chk>0</Ro2Chk>
            <Ro3Chk>0</Ro3Chk>
            <Ir1Chk>1</Ir1Chk>
            <Ir2Chk>0</Ir2Chk>
            <Ra1Chk>0</Ra1Chk>
            <Ra2Chk>0</Ra2Chk>
            <Ra3Chk>0</Ra3Chk>
            <Im1Chk>1</Im1Chk>
            <Im2Chk>0</Im2Chk>
            <OnChipMemories>
              <Ocm1>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm1>
              <Ocm2>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm2>
              <Ocm3>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm3>
              <Ocm4>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm4>
              <Ocm5>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm5>
              <Ocm6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm6>
              <IRAM>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x1000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x4000</Size>
              </IROM>
              <XRAM>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </XRAM>
              <OCR_RVCT1>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT1>
              <OCR_RVCT2>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT2>
              <OCR_RVCT3>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT3>
              <OCR_RVCT4>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x4000</Size>
              </OCR_RVCT4>
              <OCR_RVCT5>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT5>
              <OCR_RVCT6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT6>
              <OCR_RVCT7>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT7>
              <OCR_RVCT8>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT8>
              <OCR_RVCT9>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x1000</Size>
              </OCR_RVCT9>
              <OCR_RVCT10>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT10>
            </OnChipMemories>
            <RvctStartVector></RvctStartVector>
          </ArmAdsMisc>
          <Cads>
            <interw>1</interw>
            <Optim>1</Optim>
            <oTime>0</oTime>
            <SplitLS>0</SplitLS>
            <OneElfS>1</OneElfS>
            <Strict>0</Strict>
            <EnumInt>0</EnumInt>
            <PlainCh>0</PlainCh>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <wLevel>2</wLevel>
            <uThumb>0</uThumb>
            <uSurpInc>0</uSurpInc>
            <uC99>0</uC99>
            <uGnu>0</uGnu>
            <useXO>0</useXO>
            <v6Lang>6</v6Lang>
            <v6LangP>9</v6LangP>
            <vShortEn>1</vShortEn>
            <vShortWch>1</vShortWch>
            <v6Lto>0</v6Lto>
            <v6WtE>1</v6WtE>
            <v6Rtti>0</v6Rtti>
            <VariousControls>
              <MiscControls>-Wpedantic -Wextra</MiscControls>
              <Define>DEBUG,STM32F103xB</Define>
              <Undefine></Undefine>
              <IncludePath>../inc</IncludePath>
            </VariousControls>
          </Cads>
          <Aads>
            <interw>1</interw>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <thumb>0</thumb>
            <SplitLS>0</SplitLS>
            <SwStkChk>0</SwStkChk>
            <NoWarn>0</NoWarn>
            <uSurpInc>0</uSurpInc>
            <useXO>0</useXO>
            <ClangAsOpt>1</ClangAsOpt>
            <VariousControls>
              <MiscControls></MiscControls>
              <Define></Define>
              <Undefine></Undefine>
              <IncludePath></IncludePath>
            </VariousControls>
          </Aads>
          <LDads>
            <umfTarg>1</umfTarg>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <noStLib>0</noStLib>
            <RepFail>1</RepFail>
            <useFile>0</useFile>
            <TextAddressRange>0x08000000</TextAddressRange>
            <DataAddressRange>0x20000000</DataAddressRange>
            <pXoBase></pXoBase>
            <ScatterFile></ScatterFile>
            <IncludeLibs></IncludeLibs>
            <IncludeLibsPath></IncludeLibsPath>
            <Misc></Misc>
            <LinkerInputFile></LinkerInputFile>
            <DisabledWarnings></DisabledWarnings>
          </LDads>
        </TargetArmAds>
      </TargetOption>
      <Groups>
        <Group>
          <GroupName>src</GroupName>
          <Files>
            <File>
              <FileName>main.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\main.c</FilePath>
            </File>
            <File>
              <FileName>startup_stm32f103xb.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32f103xb.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32f1xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32f1xx.c</FilePath>
            </File>
          </Files>
        </Group>
      </Groups>
    </Target>
    <Target>
      <TargetName>Release</TargetName>
      <ToolsetNumber>0x4</ToolsetNumber>
      <ToolsetName>ARM-ADS</ToolsetName>
      <uAC6>1</uAC6>
      <TargetOption>
        <TargetCommonOption>
          <Device>STM32F103CB</Device>
          <Vendor>STMicroelectronics</Vendor>
          <Cpu>IRAM(0x20000000,0x00001000) IROM(0x08000000,0x00004000) CPUTYPE("Cortex-M3") CLOCK(8000000) ELITTLE</Cpu>
          <FlashUtilSpec></FlashUtilSpec>
          <StartupFile></StartupFile>
          <FlashDriverDll></FlashDriverDll>
          <DeviceId></DeviceId>
          <RegisterFile></RegisterFile>
          <MemoryEnv></MemoryEnv>
          <Cmp></Cmp>
          <Asm></Asm>
          <Linker></Linker>
          <OHString></OHString>
          <InfinionOptionDll></InfinionOptionDll>
          <SLE66CMisc></SLE66CMisc>
          <SLE66AMisc></SLE66AMisc>
          <SLE66LinkerMisc></SLE66LinkerMisc>
          <SFDFile>..\STM32F103xx.svd</SFDFile>
          <bCustSvd>0</bCustSvd>
          <UseEnv>0</UseEnv>
          <BinPath></BinPath>
          <IncludePath></IncludePath>
          <LibPath></LibPath>
          <RegisterFilePath></RegisterFilePath>
          <DBRegisterFilePath></DBRegisterFilePath>
          <TargetStatus>
            <Error>0</Error>
            <ExitCodeStop>0</ExitCodeStop>
            <ButtonStop>0</ButtonStop>
            <NotGenerated>0</NotGenerated>
            <InvalidFlash>1</InvalidFlash>
          </TargetStatus>
          <OutputDirectory>.\Objects\</OutputDirectory>
          <OutputName>Project</OutputName>
          <CreateExecutable>1</CreateExecutable>
          <CreateLib>0</CreateLib>
          <CreateHexFile>1</CreateHexFile>
          <DebugInformation>0</DebugInformation>
          <BrowseInformation>0</BrowseInformation>
          <ListingPath>.\Listings\</ListingPath>
          <HexFormatSelection>1</HexFormatSelection>
          <Merge32K>0</Merge32K>
          <CreateBatchFile>0</CreateBatchFile>
          <BeforeCompile>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopU1X>0</nStopU1X>
            <nStopU2X>0</nStopU2X>
          </BeforeCompile>
          <BeforeMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopB1X>0</nStopB1X>
            <nStopB2X>0</nStopB2X>
          </BeforeMake>
          <AfterMake>
            <RunUserProg1>0</RunUserProg1>
            <RunUserProg2>0</RunUserProg2>
            <UserProg1Name></UserProg1Name>
            <UserProg2Name></UserProg2Name>
            <UserProg1Dos16Mode>0</UserProg1Dos16Mode>
            <UserProg2Dos16Mode>0</UserProg2Dos16Mode>
            <nStopA1X>0</nStopA1X>
            <nStopA2X>0</nStopA2X>
          </AfterMake>
          <SelectedForBatchBuild>0</SelectedForBatchBuild>
          <SVCSIdString></SVCSIdString>
        </TargetCommonOption>
        <CommonProperty>
          <UseCPPCompiler>0</UseCPPCompiler>
          <RVCTCodeConst>0</RVCTCodeConst>
          <RVCTZI>0</RVCTZI>
          <RVCTOtherData>0</RVCTOtherData>
          <ModuleSelection>0</ModuleSelection>
          <IncludeInBuild>1</IncludeInBuild>
          <AlwaysBuild>0</AlwaysBuild>
          <GenerateAssemblyFile>0</GenerateAssemblyFile>
          <AssembleAssemblyFile>0</AssembleAssemblyFile>
          <PublicsOnly>0</PublicsOnly>
          <StopOnExitCode>3</StopOnExitCode>
          <CustomArgument></CustomArgument>
          <IncludeLibraryModules></IncludeLibraryModules>
          <ComprImg>1</ComprImg>
        </CommonProperty>
        <DllOption>
          <SimDllName>SARMCM3.DLL</SimDllName>
          <SimDllArguments> -REMAP </SimDllArguments>
          <SimDlgDll>DARMCM1.DLL</SimDlgDll>
          <SimDlgDllArguments>-pCM0</SimDlgDllArguments>
          <TargetDllName>SARMCM3.DLL</TargetDllName>
          <TargetDllArguments> </TargetDllArguments>
          <TargetDlgDll>TARMCM1.DLL</TargetDlgDll>
          <TargetDlgDllArguments>-pCM0</TargetDlgDllArguments>
        </DllOption>
        <DebugOption>
          <OPTHX>
            <HexSelection>1</HexSelection>
            <HexRangeLowAddress>0</HexRangeLowAddress>
            <HexRangeHighAddress>0</HexRangeHighAddress>
            <HexOffset>0</HexOffset>
            <Oh166RecLen>16</Oh166RecLen>
          </OPTHX>
        </DebugOption>
        <Utilities>
          <Flash1>
            <UseTargetDll>1</UseTargetDll>
            <UseExternalTool>0</UseExternalTool>
            <RunIndependent>0</RunIndependent>
            <UpdateFlashBeforeDebugging>1</UpdateFlashBeforeDebugging>
            <Capability>1</Capability>
            <DriverSelection>4096</DriverSelection>
          </Flash1>
          <bUseTDR>1</bUseTDR>
          <Flash2>BIN\UL2CM3.DLL</Flash2>
          <Flash3>"" ()</Flash3>
          <Flash4></Flash4>
          <pFcarmOut></pFcarmOut>
          <pFcarmGrp></pFcarmGrp>
          <pFcArmRoot></pFcArmRoot>
          <FcArmLst>0</FcArmLst>
        </Utilities>
        <TargetArmAds>
          <ArmAdsMisc>
            <GenerateListings>0</GenerateListings>
            <asHll>1</asHll>
            <asAsm>1</asAsm>
            <asMacX>1</asMacX>
            <asSyms>1</asSyms>
            <asFals>1</asFals>
            <asDbgD>1</asDbgD>
            <asForm>1</asForm>
            <ldLst>0</ldLst>
            <ldmm>1</ldmm>
            <ldXref>1</ldXref>
            <BigEnd>0</BigEnd>
            <AdsALst>0</AdsALst>
            <AdsACrf>1</AdsACrf>
            <AdsANop>0</AdsANop>
            <AdsANot>0</AdsANot>
            <AdsLLst>1</AdsLLst>
            <AdsLmap>1</AdsLmap>
            <AdsLcgr>1</AdsLcgr>
            <AdsLsym>1</AdsLsym>
            <AdsLszi>1</AdsLszi>
            <AdsLtoi>1</AdsLtoi>
            <AdsLsun>1</AdsLsun>
            <AdsLven>1</AdsLven>
            <AdsLsxf>1</AdsLsxf>
            <RvctClst>0</RvctClst>
            <GenPPlst>0</GenPPlst>
            <AdsCpuType>"Cortex-M3"</AdsCpuType>
            <RvctDeviceName></RvctDeviceName>
            <mOS>0</mOS>
            <uocRom>0</uocRom>
            <uocRam>0</uocRam>
            <hadIROM>1</hadIROM>
            <hadIRAM>1</hadIRAM>
            <hadXRAM>0</hadXRAM>
            <uocXRam>0</uocXRam>
            <RvdsVP>0</RvdsVP>
            <RvdsMve>0</RvdsMve>
            <RvdsCdeCp>0</RvdsCdeCp>
            <hadIRAM2>0</hadIRAM2>
            <hadIROM2>0</hadIROM2>
            <StupSel>8</StupSel>
            <useUlib>1</useUlib>
            <EndSel>0</EndSel>
            <uLtcg>0</uLtcg>
            <nSecure>0</nSecure>
            <RoSelD>3</RoSelD>
            <RwSelD>3</RwSelD>
            <CodeSel>0</CodeSel>
            <OptFeed>0</OptFeed>
            <NoZi1>0</NoZi1>
            <NoZi2>0</NoZi2>
            <NoZi3>0</NoZi3>
            <NoZi4>0</NoZi4>
            <NoZi5>0</NoZi5>
            <Ro1Chk>0</Ro1Chk>
            <Ro2Chk>0</Ro2Chk>
            <Ro3Chk>0</Ro3Chk>
            <Ir1Chk>1</Ir1Chk>
            <Ir2Chk>0</Ir2Chk>
            <Ra1Chk>0</Ra1Chk>
            <Ra2Chk>0</Ra2Chk>
            <Ra3Chk>0</Ra3Chk>
            <Im1Chk>1</Im1Chk>
            <Im2Chk>0</Im2Chk>
            <OnChipMemories>
              <Ocm1>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm1>
              <Ocm2>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm2>
              <Ocm3>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm3>
              <Ocm4>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm4>
              <Ocm5>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm5>
              <Ocm6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </Ocm6>
              <IRAM>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x1000</Size>
              </IRAM>
              <IROM>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x4000</Size>
              </IROM>
              <XRAM>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </XRAM>
              <OCR_RVCT1>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT1>
              <OCR_RVCT2>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT2>
              <OCR_RVCT3>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT3>
              <OCR_RVCT4>
                <Type>1</Type>
                <StartAddress>0x8000000</StartAddress>
                <Size>0x4000</Size>
              </OCR_RVCT4>
              <OCR_RVCT5>
                <Type>1</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT5>
              <OCR_RVCT6>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT6>
              <OCR_RVCT7>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT7>
              <OCR_RVCT8>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT8>
              <OCR_RVCT9>
                <Type>0</Type>
                <StartAddress>0x20000000</StartAddress>
                <Size>0x1000</Size>
              </OCR_RVCT9>
              <OCR_RVCT10>
                <Type>0</Type>
                <StartAddress>0x0</StartAddress>
                <Size>0x0</Size>
              </OCR_RVCT10>
            </OnChipMemories>
            <RvctStartVector></RvctStartVector>
          </ArmAdsMisc>
          <Cads>
            <interw>1</interw>
            <Optim>6</Optim>
            <oTime>0</oTime>
            <SplitLS>0</SplitLS>
            <OneElfS>1</OneElfS>
            <Strict>0</Strict>
            <EnumInt>0</EnumInt>
            <PlainCh>0</PlainCh>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <wLevel>2</wLevel>
            <uThumb>0</uThumb>
            <uSurpInc>0</uSurpInc>
            <uC99>0</uC99>
            <uGnu>0</uGnu>
            <useXO>0</useXO>
            <v6Lang>6</v6Lang>
            <v6LangP>9</v6LangP>
            <vShortEn>1</vShortEn>
            <vShortWch>1</vShortWch>
            <v6Lto>1</v6Lto>
            <v6WtE>1</v6WtE>
            <v6Rtti>0</v6Rtti>
            <VariousControls>
              <MiscControls>-Wpedantic -Wextra</MiscControls>
              <Define>NDEBUG,STM32F103xB</Define>
              <Undefine></Undefine>
              <IncludePath>../inc</IncludePath>
            </VariousControls>
          </Cads>
          <Aads>
            <interw>1</interw>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <thumb>0</thumb>
            <SplitLS>0</SplitLS>
            <SwStkChk>0</SwStkChk>
            <NoWarn>0</NoWarn>
            <uSurpInc>0</uSurpInc>
            <useXO>0</useXO>
            <ClangAsOpt>1</ClangAsOpt>
            <VariousControls>
              <MiscControls></MiscControls>
              <Define></Define>
              <Undefine></Undefine>
              <IncludePath></IncludePath>
            </VariousControls>
          </Aads>
          <LDads>
            <umfTarg>1</umfTarg>
            <Ropi>0</Ropi>
            <Rwpi>0</Rwpi>
            <noStLib>0</noStLib>
            <RepFail>1</RepFail>
            <useFile>0</useFile>
            <TextAddressRange>0x08000000</TextAddressRange>
            <DataAddressRange>0x20000000</DataAddressRange>
            <pXoBase></pXoBase>
            <ScatterFile></ScatterFile>
            <IncludeLibs></IncludeLibs>
            <IncludeLibsPath></IncludeLibsPath>
            <Misc></Misc>
            <LinkerInputFile></LinkerInputFile>
            <DisabledWarnings></DisabledWarnings>
          </LDads>
        </TargetArmAds>
      </TargetOption>
      <Groups>
        <Group>
          <GroupName>src</GroupName>
          <Files>
            <File>
              <FileName>main.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\main.c</FilePath>
            </File>
            <File>
              <FileName>startup_stm32f103xb.s</FileName>
              <FileType>2</FileType>
              <FilePath>..\MDK-ARM\startup_stm32f103xb.s</FilePath>
            </File>
            <File>
              <FileName>system_stm32f1xx.c</FileName>
              <FileType>1</FileType>
              <FilePath>..\src\system_stm32f1xx.c</FilePath>
            </File>
          </Files>
        </Group>
      </Groups>
    </Target>
  </Targets>

  <RTE>
    <apis/>
    <components/>
    <files/>
  </RTE>

  <LayerInfo>
    <Layers>
      <Layer>
        <LayName>Project</LayName>
        <LayPrjMark>1</LayPrjMark>
      </Layer>
    </Layers>
  </LayerInfo>

</Project>

EOF

cat > "project.jdebug" << 'EOF'
void OnProjectLoad (void) {
  Project.AddPathSubstitute (".", "$(ProjectDir)");
  Project.AddPathSubstitute (".", "$(ProjectDir)");
  Project.SetDevice ("STM32F103C8");
  Project.SetHostIF ("USB", "");
  Project.SetTargetIF ("SWD");
  Project.SetTIFSpeed ("4 MHz");
  Project.AddSvdFile ("$(InstallDir)/Config/CPU/Cortex-M3.svd");
  Project.AddSvdFile ("$(InstallDir)/Config/Peripherals/ARMv6M.svd");
  Project.AddSvdFile ("$(ProjectDir)/STM32F103xx.svd");
  File.Open ("$(ProjectDir)/_build/Project.elf");
}

void AfterTargetReset (void) {
  _SetupTarget();
}

void AfterTargetDownload (void) {
  _SetupTarget();
}

void _SetupTarget(void) {
  unsigned int SP;
  unsigned int PC;
  unsigned int VectorTableAddr;

  VectorTableAddr = Elf.GetBaseAddr();
  SP = Target.ReadU32(VectorTableAddr);
  if (SP != 0xFFFFFFFF) {
    Target.SetReg("SP", SP);
  }
  PC = Elf.GetEntryPointPC();
  if (PC != 0xFFFFFFFF) {
    Target.SetReg("PC", PC);
  } else {
    Util.Error("Project script error: failed to set up entry point PC", 1);
  }
}
EOF

create_file "stm32f103xb.jflash" << 'EOF'
/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4AewAwZdABBhAOGFYzOihg56UIqKCKQrnqKasrAxa6gWaeZG86Pk+G/iEId5CVjqnEwXAprd+mfglT4i426SWo/xS7YaD+CzdQCIqK5WCRH/2RwmT8+YuwJBPpqcRsdUYfOKkq4h0s3MNcWVwMPOzcra1Mz2E7c/ufx7PcVXHoKnnAGUMvm4KmD9CsTR2PmMFFMlH3wr484iM7+vJvsy8EiQQ1nbBIoLenldsybldPbO95PH68xcmlmXJYuhcKYKQVFjBWAmswQvjVHT2Fwde7zHqLfzQa9KvCPkWbD/ALiUhL4Dum0p3xlKrgWSUlBInXyh6b0TsLznCs9ZlguX3w11XmdhG4uPslLk3mxej0M67O3QE/SUKTJU9He8ODHT5mZjCFMhqDzCfeHu7lVBpoL8TSqwEaUlJYxA30zMB13OUSfdRLd7v20DJJyH0+HTKlmlzkOD5DDabNTQJZheesSnHSv8D4iWlPFyWW5Vv67JsOKSl2IR0THA1JU9FqiIMc7/c4NOFKY/9FSx5Sgyjwwa2TUzIgZhFm+mRwzA+Nzy1tK+u4Ac7ldi7nph+o8Oin97fIVEUW48dOkUr1ZyJI2mGcB1IDaHkWlE0ZWCvZdwhe9alKcddHBtVo6LG/Qrr97ZY8xMfxRQYPmfToMwh9gNi8Lc/qamJwdFd1riK4GOKWhCGPcypXvuWzd4J+rmlCjBytqdhPp2EKhqcA/dP2bRMFG9zUNKNkmGex8KwNSIZjSyGwbLdEdobqjABUt9puOl1CMMGJ4gyWAsgeWE3ZKNbYEsS0hoDzrO04Nt/jc+3V0zddOMtpodAn5ZKjI3hr2PuQ3maeqz94m57+4beTf+sYd0YNxV9lEckzBJribIGHBnyu4BHhM1nvKKZcW4FKPDd9nVesB3ea6nHdkeAMkCHwyLqqnx7qSRxrZV/ppKZxc8XaN5qPClUBfig0Iya7UGyHNxXoGcnPVQ0yK+HxbKal4NRMQNVzrXginnC9j32tqE5pHuUvlbWQ0BrHhXKQDYweOiClDt01GWAAAAAJ84fh2c2eeFAAGiBrEPAABa/1O2scRn+wIAAAAABFla
EOF

# Create main.c file in src directory from embedded data using Here Document
main_c_file="${directories[1]}/main.c"
if [ ! -f "$main_c_file" ]; then
  op_counter=$((op_counter + 1))
  cat << 'EOF' > "$main_c_file"
#include "main.h"


int main(void) {
  /* Main program loop: initialize, process continuously, and idle between operations */
  for (init(); process(); idle());
}


/**
 * @brief  Returns pointer to the system uptime counter
 * @retval Pointer to volatile 64-bit uptime value (milliseconds/ticks)
 */
__STATIC_FORCEINLINE __SYSTICK_VOLATILE uint64_t * uptime(void) {
  extern __SYSTICK_VOLATILE uint64_t system_uptime;
  return &system_uptime;
}


/**
 * @brief  SysTick event processing - handles uptime increment and LED toggle
 * @note   Implementation is shared between polling and interrupt modes
 *         depending on SYSTICK_IRQ_EN configuration
 */
#if YES == SYSTICK_IRQ_EN

/* IRQ mode: Empty inline stub; actual implementation runs in interrupt handler */
__STATIC_FORCEINLINE void process_systick_event(void) {}

/* SysTick interrupt service routine */
void SysTick_Handler(void);
void SysTick_Handler(void) {

#else

/* Polling mode: Check COUNTFLAG before processing */
__STATIC_FORCEINLINE void process_systick_event(void) {
  if (0 == (SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk)) {
    return;  /* No event occurred, exit early */
  }
  
#endif

  /* ========== Shared implementation (IRQ or polling) ========== */
  
  /* Increment uptime counter and toggle PC13 LED (BluePill onboard LED)
   * based on bit 9 state. This creates a blink period of 2^10 = 1024 ticks. */
  GPIOC->BSRR = ++*uptime() & (1 << 9) ? GPIO_BSRR_BS13 : GPIO_BSRR_BR13;

}


/**
 * @brief  Idle state handler - processes pending events during main loop idle time
 * @note   Called repeatedly from main loop when no work is pending
 */
__STATIC_FORCEINLINE void idle(void) {
  process_systick_event();
} /* idle() */


/**
 * @brief  Main processing routine - executes application logic
 * @retval Non-zero to continue main loop execution, zero to exit
 */
__STATIC_FORCEINLINE unsigned process(void) {
  /* TODO: Add application-specific processing here */
  return !0;  /* Always continue loop */
} /* process() */


/* System uptime counter in SysTick ticks (incremented every SysTick event) */
__SYSTICK_VOLATILE uint64_t system_uptime = 0;

EOF
  echo "File $main_c_file created."
fi


# URLs for files
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Source/Templates/system_stm32f1xx.c
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Source/Templates/gcc/startup_stm32f103xb.s
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Source/Templates/arm/startup_stm32f103xb.s
#
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Include/system_stm32f1xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Include/stm32f1xx.h
#    https://raw.githubusercontent.com/STMicroelectronics/cmsis_device_f1/master/Include/stm32f103xb.h
#
#               https://github.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include
#
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_compiler.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armclang.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_gcc.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_iccarm.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_version.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/core_cm3.h
#    https://raw.githubusercontent.com/ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/cmsis_armcc.h
#
#    https://raw.githubusercontent.com/cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F103xx.svd
     
     

fname1=("system_stm32f1xx.c" "startup_stm32f103xb.s")
fname2=("system_stm32f1xx.h" "stm32f1xx.h" "stm32f103xb.h")
fname3=("cmsis_compiler.h" "cmsis_armclang.h" "cmsis_gcc.h" "cmsis_iccarm.h" "cmsis_version.h" "core_cm3.h" "cmsis_armcc.h")

raw_github="https://raw.githubusercontent.com/"

url1="${raw_github}STMicroelectronics/cmsis-device-f1/refs/heads/master"
url2="${raw_github}ARM-software/CMSIS_5/refs/heads/master/CMSIS/Core/Include/"
url3="${raw_github}cmsis-svd/cmsis-svd-data/refs/heads/main/data/STMicro/STM32F103xx.svd"

# Function to check if a file exists and download it if it doesn't
download_file() {
    local url="$1"
    local dest="$2"
    
    if [ ! -f "$dest" ]; then
        if curl -fsSL "$url" | tr -cd '\11\12\15\40-\176' > "$dest"; then
            if [ -s "$dest" ]; then  # Check file is not empty
                ((++op_counter))
                echo "File $dest downloaded."
            else
                echo "Error: Downloaded file $dest is empty" >&2
                rm -f "$dest"
                return 1
            fi
        else
            echo "Error: Failed to download $url" >&2
            return 1
        fi
    fi
}

download_file "${url1}/Source/Templates/${fname1[0]}" "${directories[1]}/${fname1[0]}"
download_file "${url1}/Source/Templates/gcc/${fname1[1]}" "${directories[1]}/${fname1[1]}"
download_file "${url1}/Source/Templates/arm/${fname1[1]}" "${directories[2]}/${fname1[1]}"
download_file "${url3}" "STM32F103xx.svd"

# Download files
for filename in "${fname2[@]}"
do
  download_file "${url1}/Include/${filename}" "${directories[0]}/${filename}"
done

for filename in "${fname3[@]}"
do
  download_file "${url2}${filename}" "${directories[0]}/${filename}"
done

echo -e "\nBuilding sources..\n"

if make debug; then
    echo ""
    echo "====================================="
    echo "Project setup complete!"
    echo "  Operations performed: $op_counter"
    echo "  Project directory: $base_dir"
    echo "  Build: SUCCESS"
    echo "====================================="
    echo ""
else
    echo ""
    echo "====================================="
    echo "Build FAILED!"
    echo "  Check error messages above"
    echo "====================================="
    echo ""
    exit 1
fi

press_any_key
