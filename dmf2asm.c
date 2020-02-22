#define PROGNAME "dmf2asm v0.1"

#include <inttypes.h>

#ifndef u_int32_t
#define u_int32_t uint32_t
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <zlib.h>

void usage(char *programname);
void getDmfHeader(void);
int FindPattern(void);
int SqueezePatterns(void);

char *zinputbuffer;
char *inputbuffer;
int TotalInstruments;

#pragma pack(1)			// no field padding in our structs

    // DMF Header, interpreted from the info from http://www.deflemask.com/DMF_SPECS.txt

struct DmfHeader {
    char Magic[16];			// must be ".DelekDefleMask."
    unsigned char FileVersion;		// must be 24 (0x18) for DefleMask v0.12.0
    unsigned char System;		// SMD=2 SMD+=18 SMS=3 GAMEBOY=4 PCENG=5 NES=6 C64=7 C64alt=8 YM2151=8
    unsigned char SongNameSize;		// size of upcoming field
    char SongName[256];			// in the DMF file this is a variable-sized field, but during DMF read we convert to fixed-width
    unsigned char AuthorNameSize;	// size of upcoming field
    char AuthorName[256];		// in the DMF file this is a variable-sized field, but during DMF parsing we convert to fixed-width
    unsigned char HighlightAInPatterns;
    unsigned char HighlightBInPatterns;
    unsigned char TimeBase;
    unsigned char TickTime1;
    unsigned char TickTime2;
    unsigned char FramesMode;
    unsigned char UseCustomHz;
    unsigned char CustomHzVal1;
    unsigned char CustomHzVal2;
    unsigned char CustomHzVal3;
    u_int32_t RowsPerPattern;
    unsigned char RowsInPatternMatrix;
} OurDmfHeader;

#define MAXINSTRUMENTS 64

struct DmfInstrument {
    unsigned char InstrumentNameSize;
    char InstrumentName[256];
    unsigned char InstrumentIndex;
    unsigned char InstrumentMode;

    unsigned char ALG;
    unsigned char FB;
    unsigned char PMS;
    unsigned char AMS;

    unsigned char AM_1;
    unsigned char AR_1;
    unsigned char DR_1;
    unsigned char MULT_1;
    unsigned char RR_1;
    unsigned char SL_1;
    unsigned char TL_1;
    unsigned char DT2_1;
    unsigned char RS_1;
    unsigned char DT_1;
    unsigned char D2R_1;
    unsigned char SSGMODE_1;	// (BIT 4 = 0 Disabled, 1 Enabled, BITS 0,1,2 SSG_MODE)

    unsigned char AM_2;
    unsigned char AR_2;
    unsigned char DR_2;
    unsigned char MULT_2;
    unsigned char RR_2;
    unsigned char SL_2;
    unsigned char TL_2;
    unsigned char DT2_2;
    unsigned char RS_2;
    unsigned char DT_2;
    unsigned char D2R_2;
    unsigned char SSGMODE_2;	// (BIT 4 = 0 Disabled, 1 Enabled, BITS 0,1,2 SSG_MODE)

    unsigned char AM_3;
    unsigned char AR_3;
    unsigned char DR_3;
    unsigned char MULT_3;
    unsigned char RR_3;
    unsigned char SL_3;
    unsigned char TL_3;
    unsigned char DT2_3;
    unsigned char RS_3;
    unsigned char DT_3;
    unsigned char D2R_3;
    unsigned char SSGMODE_3;	// (BIT 4 = 0 Disabled, 1 Enabled, BITS 0,1,2 SSG_MODE)

    unsigned char AM_4;
    unsigned char AR_4;
    unsigned char DR_4;
    unsigned char MULT_4;
    unsigned char RR_4;
    unsigned char SL_4;
    unsigned char TL_4;
    unsigned char DT2_4;
    unsigned char RS_4;
    unsigned char DT_4;
    unsigned char D2R_4;
    unsigned char SSGMODE_4;	// (BIT 4 = 0 Disabled, 1 Enabled, BITS 0,1,2 SSG_MODE)

} OurDmfInstruments[MAXINSTRUMENTS];

unsigned char System;		// SMD=2 SMD+=18 SMS=3 GAMEBOY=4 PCENG=5 NES=6 C64=7 C64alt=8 YM2151=8
char *SystemList[] = {
    "Invalid" /*0 */ , "Invalid" /*1 */ , "Sega Genesis" /*2 */ , "Sega Master System" /*3 */ ,
    "Gameboy" /*4 */ , "PC Engine" /*5 */ , "NES" /*6 */ , "C64 (SID 8580)" /*7 */ , "YM2151" /*8 */ ,
    "Invalid" /*9 */ , "Invalid" /*10 */ , "Invalid" /*11 */ , "Invalid" /*12 */ , "Invalid" /*13 */ ,
    "Invalid" /*14 */ , "Invalid" /*15 */ , "Invalid" /*16 */ , "Invalid" /*17 */ ,
    "Sega Genesis (ext. ch3)" /*18 */ , "Invalid" /*19 */ , "Invalid" /*20 */ , "Invalid" /*21 */ ,
    "Invalid" /*22 */ , "C64 (SID 6581)" /*23 */ , "Invalid" /*24 */
};

// How many channels each DMF system has. 
unsigned char SystemTotalChannels[] = { 0, 0, 10, 4, 4, 6, 5, 3, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 0, 0, 0, 0, 3, 0 };

// we use the above channel count to navigate the data structures, but this define is for the actual # 
// of channels we parse for YM2151, since we're only interested in FM data. (The YM2151 system has 5x 
// PCM channels after the FM ones.)
#define FMCHANNELS 8

// we import the DMF into these tables, so we can massage their export for the 6502 however we please
unsigned char YM2151Registers[256];
int PatternMatrixDMF[8][256];
int PatternMatrixOut[8][256];
unsigned char PatternsOut[2048][256];
unsigned char PatternsUsed[8][256];
int GlobalPatternTotal = 0;	// total of global PatternsOut patterns.

char *AsmName = NULL;


char *DmfFileName, *AsmFileName;
FILE *DmfFileHandle, *AsmFileHandle;


int main(int argc, char **argv)
{
    int c;
    int chindex, patindex;
    int errflg = 0;

    DmfFileName = NULL;
    AsmFileName = NULL;
    AsmFileHandle = stdout;

    //clear our intermediate storage arrays
    memset(&YM2151Registers, 0, sizeof(YM2151Registers));
    memset(&PatternsOut, 0, sizeof(PatternsOut));
    memset(&PatternMatrixDMF, 0, sizeof(PatternMatrixDMF));
    memset(&PatternMatrixOut, 0, sizeof(PatternMatrixOut));
    memset(&PatternsUsed, 0, sizeof(PatternsUsed));

    memset(&OurDmfInstruments, 0, sizeof(OurDmfInstruments));

    while ((c = getopt(argc, argv, ":i:o:n:")) != -1)
    {
	switch (c)
	{
	case 'o':
	    AsmFileName = optarg;
	    break;
	case 'i':
	    DmfFileName = optarg;
	    break;
	case 'n':
	    AsmName = optarg;
	    break;
	case '?':
	    fprintf(stderr, "ERR: unrecognised option \"-%c\"\n", optopt);
	    errflg++;
	    break;
	default:
	    errflg++;
	    break;
	}
    }
    if (DmfFileName == NULL)
    {
	fprintf(stderr, "ERR: the -i input filename argument is required. aborting.\n");
	errflg++;
    }
    if (AsmName == NULL)
    {
	fprintf(stderr, "WARN: A song label name wasn't provided via the -n switch.\n");
	fprintf(stderr, "      This will make it difficult to use multiple songs with the tracker.\n");
	AsmName = "mysong";
    }
    if (errflg)
    {
	usage(argv[0]);
	return (2);
    }

    DmfFileHandle = fopen(DmfFileName, "rb");
    if (DmfFileHandle == NULL)
    {
	fprintf(stderr, "ERR: the input file couldn't be opened. aborting.\n");
	exit(1);
    }

    if (AsmFileName != NULL)
    {
	// an output filename was requested. Let's reassign stdout...
	if (freopen(AsmFileName, "w", stdout) == NULL)
	{
	    fprintf(stderr, "ERR: the output file couldn't be opened for writing. aborting.\n");
	    exit(1);
	}
    }

    // get the DMF file size...
    fseek(DmfFileHandle, 0, SEEK_END);
    unsigned long DmfZSize = ftell(DmfFileHandle);
    fseek(DmfFileHandle, 0, SEEK_SET);

    // We use zlib "uncompress" which is blind in terms of the expected output size.
    // For now we just over-size the output buffer, which should be more than enough
    // for a real DMF file.  

    unsigned long DmfSize = ((DmfZSize * 200 > 0xA00000) ? DmfZSize * 200 : 0xA00000);

    zinputbuffer = malloc(DmfZSize);
    inputbuffer = malloc(DmfSize);
    if ((zinputbuffer == NULL) || (inputbuffer == NULL))
    {
	fprintf(stderr, "ERR: couldn't allocate memory buffer. aborting.\n");
	exit(1);
    }
    if (fread(zinputbuffer, 1, DmfZSize, DmfFileHandle) <= 0)
    {
	fprintf(stderr, "ERR: couldn't load input file into memory buffer. aborting.\n");
	exit(1);
    }

    // now we need to decompress the header data...
    uncompress((Bytef *) inputbuffer, &DmfSize, (Bytef *) zinputbuffer, DmfZSize);

    memcpy(&OurDmfHeader, inputbuffer, 19);

    if (memcmp(OurDmfHeader.Magic, ".DelekDefleMask.", 16) != 0)
    {
	fprintf(stderr, "ERR: the input file doesn't have a Deflemask signature. aborting.\n");
	exit(1);
    }

    if (OurDmfHeader.FileVersion != 24)
    {
	fprintf(stderr, "WARN: the DMF file version %d is unknown to this utility.\n", OurDmfHeader.FileVersion);
    }

    if (OurDmfHeader.System != 8)
    {
	fprintf(stderr, "ERR: the DMF target system for %s isn't supported by this exporter. Use the YM2151 format.\n",
		SystemList[OurDmfHeader.System]);
	exit(1);
    }

    // fully extract the rest of the header, by converting variable-width strings to fixed-width zero terminated
    char *VariableStringPointer;
    VariableStringPointer = inputbuffer + 19;	//point to start of SongName string, if it exists

    memset(OurDmfHeader.SongName, 0, 256);
    if (OurDmfHeader.SongNameSize > 0)
    {
	memcpy(OurDmfHeader.SongName, VariableStringPointer, OurDmfHeader.SongNameSize);
	OurDmfHeader.SongName[255] = 0;	// ensure zero termination, in the unusual case of a 256-byte string
    }
    else
    {
	strcat(OurDmfHeader.SongName, "[NULL]");
    }
    VariableStringPointer = VariableStringPointer + OurDmfHeader.SongNameSize;

    OurDmfHeader.AuthorNameSize = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// move to start of the Author Name field

    memset(OurDmfHeader.AuthorName, 0, 256);
    if (OurDmfHeader.AuthorNameSize > 0)
    {
	memcpy(OurDmfHeader.AuthorName, VariableStringPointer, OurDmfHeader.AuthorNameSize);
	OurDmfHeader.AuthorName[255] = 0;	// ensure zero termination, in the unusual case of a 256-byte string
    }
    else
    {
	strcat(OurDmfHeader.AuthorName, "[NULL]");
    }
    VariableStringPointer = VariableStringPointer + OurDmfHeader.AuthorNameSize;

    OurDmfHeader.HighlightAInPatterns = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field
    OurDmfHeader.HighlightBInPatterns = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.TimeBase = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.TickTime1 = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.TickTime2 = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.FramesMode = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.UseCustomHz = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.CustomHzVal1 = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field
    OurDmfHeader.CustomHzVal2 = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field
    OurDmfHeader.CustomHzVal3 = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.RowsPerPattern = (u_int32_t) VariableStringPointer[0];	// not endian-neutral
    VariableStringPointer++;	// advance to next field
    VariableStringPointer++;	// advance to next field
    VariableStringPointer++;	// advance to next field
    VariableStringPointer++;	// advance to next field

    OurDmfHeader.RowsInPatternMatrix = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// advance to next field

    // populate our PatternMatrix array...
    for (patindex = 0; patindex < OurDmfHeader.RowsInPatternMatrix; patindex++)
    {
	//fprintf(stderr,"%02x: ",patindex);
	for (chindex = 0; chindex < FMCHANNELS; chindex++)
	{
	    PatternMatrixDMF[chindex][patindex] =
		VariableStringPointer[(chindex * OurDmfHeader.RowsInPatternMatrix) + patindex];
	    PatternsUsed[chindex][PatternMatrixDMF[chindex][patindex]] = 1;	// remember this pattern was actually used
	    //fprintf(stderr," %02x ",PatternMatrixDMF[chindex][patindex]);
	}
	//fprintf(stderr,"\n");

    }

    //advance past the pattern matrix
    VariableStringPointer =
	VariableStringPointer + (OurDmfHeader.RowsInPatternMatrix * SystemTotalChannels[OurDmfHeader.System]);


    int instrument;

    //we're now pointing at the instrument definitions
    TotalInstruments = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// next field


    // we parse through all instruments up to MAXINSTRUMENTS, even though we're only interested in the first 8 FM instruments,
    // because we want to eventually wind up at the end of the instrument table.
    for (instrument = 0; instrument < TotalInstruments; instrument++)
    {
	OurDmfInstruments[instrument].InstrumentIndex = instrument;
	OurDmfInstruments[instrument].InstrumentNameSize = (unsigned char) VariableStringPointer[0];
	VariableStringPointer++;	// advance to the InstrumentName field
	memset(OurDmfInstruments[instrument].InstrumentName, 0, 256);

	if (OurDmfInstruments[instrument].InstrumentNameSize > 0)
	{
	    memcpy(OurDmfInstruments[instrument].InstrumentName, VariableStringPointer,
		   OurDmfInstruments[instrument].InstrumentNameSize);
	}
	else
	{
	    strcpy(OurDmfInstruments[instrument].InstrumentName, "[NULL]");
	}


	OurDmfInstruments[instrument].InstrumentName[255] = 0;	// ensure it's null terminated, in case it was a 256 byte name

	VariableStringPointer = VariableStringPointer + OurDmfInstruments[instrument].InstrumentNameSize;	// skip over the InstrumentName

	OurDmfInstruments[instrument].InstrumentMode = (unsigned char) VariableStringPointer[0];
	VariableStringPointer++;	// next field

	if (OurDmfInstruments[instrument].InstrumentMode == 1)	// FM
	{
	    memcpy(&(OurDmfInstruments[instrument].ALG), VariableStringPointer, 4 + (4 * 12));
	    VariableStringPointer = VariableStringPointer + 4 + (4 * 12);	// skip the FM instrument data
	}
	else
	{
	    // we should only have FM and PCM instruments, and there isn't data in this table for PCM
	    fprintf(stderr, "ERR: encountered unknown instrument type: %d. aborting.\n",
		    OurDmfInstruments[instrument].InstrumentMode);
	    exit(1);

	}

    }



    // populate registers...
    for (chindex = 0; chindex < 8; chindex++)
    {
	// 0x20-0x27 : %11FFFAAA = (L+R),FB,ALG
	// ALTERNATE : %11FFFCCC = (L+R),FL,CON
	YM2151Registers[chindex + 0x20] =
	    0xC0 | ((OurDmfInstruments[chindex].FB & 7) << 3) | (OurDmfInstruments[chindex].ALG & 7);

	// 0x38-0x3F : %-PPP--AA = Phase Modulation Sensitivity PMS, Amplitude Modulation Sensitivity AMS
	YM2151Registers[chindex + 0x38] =
	    ((OurDmfInstruments[chindex].PMS & 7) << 4) | (OurDmfInstruments[chindex].AMS & 3);

	// 0x40-0x5F : %-DDDMMMM = DT,MULT
	// ALTERNATE : %-DDDMMMM = Decay time D1T, MUL
	YM2151Registers[chindex + 0x40 + (0 * 8)] =
	    ((OurDmfInstruments[chindex].DT_1 & 7) << 4) | (OurDmfInstruments[chindex].MULT_1 & 15);
	YM2151Registers[chindex + 0x40 + (1 * 8)] =
	    ((OurDmfInstruments[chindex].DT_2 & 7) << 4) | (OurDmfInstruments[chindex].MULT_2 & 15);
	YM2151Registers[chindex + 0x40 + (2 * 8)] =
	    ((OurDmfInstruments[chindex].DT_3 & 7) << 4) | (OurDmfInstruments[chindex].MULT_3 & 15);
	YM2151Registers[chindex + 0x40 + (3 * 8)] =
	    ((OurDmfInstruments[chindex].DT_4 & 7) << 4) | (OurDmfInstruments[chindex].MULT_4 & 15);


	// 0x60-0x7F : %-TTTTTTT = Total Level TL (Volume)
	YM2151Registers[chindex + 0x60 + (0 * 8)] = (OurDmfInstruments[chindex].TL_1 & 127);
	YM2151Registers[chindex + 0x60 + (1 * 8)] = (OurDmfInstruments[chindex].TL_2 & 127);
	YM2151Registers[chindex + 0x60 + (2 * 8)] = (OurDmfInstruments[chindex].TL_3 & 127);
	YM2151Registers[chindex + 0x60 + (3 * 8)] = (OurDmfInstruments[chindex].TL_4 & 127);


	// 0x80-0x9F : %RR-AAAAA = Rate Scaling RS AR
	// ALTERNATE : %KK-AAAAA = Key Scale KS, Attack Rate AR
	YM2151Registers[chindex + 0x80 + (0 * 8)] =
	    ((OurDmfInstruments[chindex].RS_1 & 3) << 6) | (OurDmfInstruments[chindex].AR_1 & 31);
	YM2151Registers[chindex + 0x80 + (1 * 8)] =
	    ((OurDmfInstruments[chindex].RS_2 & 3) << 6) | (OurDmfInstruments[chindex].AR_2 & 31);
	YM2151Registers[chindex + 0x80 + (2 * 8)] =
	    ((OurDmfInstruments[chindex].RS_3 & 3) << 6) | (OurDmfInstruments[chindex].AR_3 & 31);
	YM2151Registers[chindex + 0x80 + (3 * 8)] =
	    ((OurDmfInstruments[chindex].RS_4 & 3) << 6) | (OurDmfInstruments[chindex].AR_4 & 31);


	// 0xA0-0xBF : %A--DDDDD = AM, DR  
	// ALTERNATE : %A--DDDDD = Amplitude Modulation Enable, Decay rate D1R
	YM2151Registers[chindex + 0xA0 + (0 * 8)] =
	    (OurDmfInstruments[chindex].AM_1 & 128) | (OurDmfInstruments[chindex].DR_1 & 31);
	YM2151Registers[chindex + 0xA0 + (1 * 8)] =
	    (OurDmfInstruments[chindex].AM_2 & 128) | (OurDmfInstruments[chindex].DR_2 & 31);
	YM2151Registers[chindex + 0xA0 + (2 * 8)] =
	    (OurDmfInstruments[chindex].AM_3 & 128) | (OurDmfInstruments[chindex].DR_3 & 31);
	YM2151Registers[chindex + 0xA0 + (3 * 8)] =
	    (OurDmfInstruments[chindex].AM_4 & 128) | (OurDmfInstruments[chindex].DR_4 & 31);

	// 0xC0-0xDF : %TT-DDDDD = deTune DT2, Decay D2R
	YM2151Registers[chindex + 0xC0 + (0 * 8)] =
	    ((OurDmfInstruments[chindex].DT2_1 & 3) << 6) | (OurDmfInstruments[chindex].D2R_1 & 31);
	YM2151Registers[chindex + 0xC0 + (1 * 8)] =
	    ((OurDmfInstruments[chindex].DT2_2 & 3) << 6) | (OurDmfInstruments[chindex].D2R_2 & 31);
	YM2151Registers[chindex + 0xC0 + (2 * 8)] =
	    ((OurDmfInstruments[chindex].DT2_3 & 3) << 6) | (OurDmfInstruments[chindex].D2R_3 & 31);
	YM2151Registers[chindex + 0xC0 + (3 * 8)] =
	    ((OurDmfInstruments[chindex].DT2_4 & 3) << 6) | (OurDmfInstruments[chindex].D2R_4 & 31);

	// 0xE0-0xFF : %SSSSRRRR = Sustain level SL, Release Rate RR 
	// ALTERNATE : %DDDDRRRR = Decay level D1L, Release Rate RR 
	YM2151Registers[chindex + 0xE0 + (0 * 8)] =
	    ((OurDmfInstruments[chindex].SL_1 & 15) << 4) | (OurDmfInstruments[chindex].RR_1 & 15);
	YM2151Registers[chindex + 0xE0 + (1 * 8)] =
	    ((OurDmfInstruments[chindex].SL_2 & 15) << 4) | (OurDmfInstruments[chindex].RR_2 & 15);
	YM2151Registers[chindex + 0xE0 + (2 * 8)] =
	    ((OurDmfInstruments[chindex].SL_3 & 15) << 4) | (OurDmfInstruments[chindex].RR_3 & 15);
	YM2151Registers[chindex + 0xE0 + (3 * 8)] =
	    ((OurDmfInstruments[chindex].SL_4 & 15) << 4) | (OurDmfInstruments[chindex].RR_4 & 15);

    }

    // VariableStringPointer is now pointing at the WAVETABLES data
    int TotalWavetables;
    TotalWavetables = (unsigned char) VariableStringPointer[0];
    VariableStringPointer++;	// next field
    if (TotalWavetables > 0)
    {
	fprintf(stderr, "ERR: encountered wavetables. aborting.\n");
	exit(1);
    }


    printf("\n");


    // VariableStringPointer is now pointing at the PATTERNS data

    int ChannelFXColumns;
    int16_t NoteVal;
    int16_t OctaveVal;

    // for now we're not using these DFM entities...
    // int16_t VolumeVal;
    // int16_t EffectCode;
    // int16_t EffectVal;
    // int16_t InstrumentVal;
    // char *Note2Str[] = { "--","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-","C-" } ;

    int noteindex;
    int effectindex;

    for (chindex = 0; chindex < SystemTotalChannels[OurDmfHeader.System]; chindex++)
    {
	ChannelFXColumns = (unsigned char) VariableStringPointer[0];
	VariableStringPointer++;
	for (patindex = 0; patindex < OurDmfHeader.RowsInPatternMatrix; patindex++)
	{
	    for (noteindex = 0; noteindex < OurDmfHeader.RowsPerPattern; noteindex++)
	    {
		NoteVal = (int16_t) VariableStringPointer[0];
		VariableStringPointer++;
		VariableStringPointer++;
		OctaveVal = (int16_t) VariableStringPointer[0];
		VariableStringPointer++;
		VariableStringPointer++;

		// VolumeVal      = (int16_t) VariableStringPointer[0];
		VariableStringPointer++;
		VariableStringPointer++;

		for (effectindex = 0; effectindex < ChannelFXColumns; effectindex++)
		{
		    // EffectCode     = (int16_t) VariableStringPointer[0];
		    VariableStringPointer++;
		    VariableStringPointer++;
		    // EffectVal      = (int16_t) VariableStringPointer[0];
		    VariableStringPointer++;
		    VariableStringPointer++;
		}


		// InstrumentVal  = (int16_t) VariableStringPointer[0];
		VariableStringPointer++;
		VariableStringPointer++;

		// we only act on the FM Channels, but we need to advance 
		// VariableStringPointer through the PCM Channels too.
		if ((chindex < FMCHANNELS) && (PatternsUsed[chindex][patindex] == 1))
		{
		    // Deflemask Note Indexes...
		    //  0   1   2   3   4   5   6   7   8   9   10  11  12
		    //  --  C#  D-  D#  E-  F-  F#  G-  G#  A-  A#  B-  C-

		    // YM2151 Note Indexes... (mind the gaps)
		    //  0   1   2   4   5   6   8   9   10  12  13  14
		    //  C#  D-  D#  E-  F-  F#  G-  G#  A-  A#  B-  C-

		    //                            --    C#  D-  D#  E-  F-  F#  G-  G#  A-  A#  B-  C-  --
		    unsigned char DFNote2YM[] = { 255, 0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, 255 };

		    if ((NoteVal == 0) && (OctaveVal == 0))
			PatternsOut[GlobalPatternTotal][noteindex] = 0xff;
		    else
		    {
			NoteVal = DFNote2YM[NoteVal & 15];

			OctaveVal = OctaveVal & 7;
			PatternsOut[GlobalPatternTotal][noteindex] = (OctaveVal << 4) | (NoteVal);
		    }
		}
	    }			// notes within pattern loop

	    if ((chindex < FMCHANNELS) && (PatternsUsed[chindex][patindex] == 1))
	    {
		int workingPatternIndex = FindPattern();

		int ni;
		for (ni = 0; ni < OurDmfHeader.RowsInPatternMatrix; ni++)
		{
		    if (PatternMatrixDMF[chindex][ni] == patindex)
			PatternMatrixOut[chindex][ni] = workingPatternIndex;
		}
		// commit this pattern only if it was novel
		if (workingPatternIndex == GlobalPatternTotal)
		    GlobalPatternTotal++;
	    }

	}			// patterns within channel loop
    }				// channel loop

    // Lastly, see if we can squeeze the pattern storage...
    while (SqueezePatterns() != 0);

    // output the comment header...
    if (strlen(DmfFileName) > 70)
	printf("  ; %s", DmfFileName);
    else
    {
	printf("  ;_");
	for (c = 0; c < ((72 - strlen(DmfFileName)) / 2); c++)
	    printf("_");
	printf(" %s ", DmfFileName);
	for (c = 0; c < ((72 - strlen(DmfFileName)) / 2); c++)
	    printf("_");
	printf("\n");
    }
    printf("\n");
    printf("  ; \n");
    printf("  ; song name                  : %s\n", OurDmfHeader.SongName);
    printf("  ; author name                : %s\n", OurDmfHeader.AuthorName);
    printf("  ; dmf file version           : %d\n", OurDmfHeader.FileVersion);
    printf("  ; converted by               : %s\n", PROGNAME);
    printf("\n");


    // output the song header...
    printf("%s_Song\n", AsmName);
    printf("   .byte $%02x ; Frames Per Tick, even rows.\n",
	   (OurDmfHeader.TickTime1) * (OurDmfHeader.TimeBase + 1) - 1);
    printf("   .byte $%02x ; Frames Per Tick, odd rows.\n", (OurDmfHeader.TickTime2) * (OurDmfHeader.TimeBase + 1) - 1);
    printf("   .byte $%02x ; pattern height, in rows.\n", OurDmfHeader.RowsPerPattern);
    printf("   .byte $%02x ; pattern matrix height, in rows.\n", OurDmfHeader.RowsInPatternMatrix);
    printf("   .byte <%s_PatternMatrix\n", AsmName);
    printf("   .byte >%s_PatternMatrix\n", AsmName);
    printf("   .byte <%s_PatternMatrixEnd\n", AsmName);
    printf("   .byte >%s_PatternMatrixEnd\n", AsmName);
    printf("\n");

    char *RegDescrip[] = {
	"",			//00-07
	"",			//08-0f
	"",			//10-17
	"",			//18-1F
	"%LRFFFCCC = L,R,FL,CON  *",	//20-27
	"%-OOONNNN = Oct,Note    *",	//28-2F
	"%KKKKKK-- = KF          *",	//30-37
	"%-PPP--AA = PMS,AMS     *",	//38-3F

	"%-TTTMMMM = DT1,MUL    OP1",	//40-47
	"%-TTTMMMM = DT1,MUL    OP3",	//48-4F
	"%-TTTMMMM = DT1,MUL    OP2",	//50-57
	"%-TTTMMMM = DT1,MUL    OP4",	//50-5F

	"%-TTTTTTT = TL         OP1",	//60-67
	"%-TTTTTTT = TL         OP3",	//68-6F
	"%-TTTTTTT = TL         OP2",	//70-67
	"%-TTTTTTT = TL         OP4",	//78-7F

	"%KK-AAAAA = KS,AR      OP1",	//80-87
	"%KK-AAAAA = KS,AR      OP3",	//88-8F
	"%KK-AAAAA = KS,AR      OP2",	//90-97
	"%KK-AAAAA = KS,AR      OP4",	//98-9F

	"%A--DDDDD = AME,D1R    OP1",	//A0-A7
	"%A--DDDDD = AME,D1R    OP3",	//A8-AF
	"%A--DDDDD = AME,D1R    OP2",	//B0-B7
	"%A--DDDDD = AME,D1R    OP4",	//B8-BF

	"%TT-DDDDD = DT2,D2R    OP1",	//C0-C7
	"%TT-DDDDD = DT2,D2R    OP3",	//C8-CF
	"%TT-DDDDD = DT2,D2R    OP2",	//D0-D7
	"%TT-DDDDD = DT2,D2R    OP4",	//D8-DF

	"%DDDDRRRR = D1L,RR     OP1",	//E0-E7
	"%DDDDRRRR = D1L,RR     OP3",	//E8-EF
	"%DDDDRRRR = D1L,RR     OP2",	//F0-F7
	"%DDDDRRRR = D1L,RR     OP4"	//F8-FF 
    };


    // output the instrument register dump...
    int x, y;
    printf("\n");
    printf("%s_InstrumentRegisters\n", AsmName);
    for (y = 4; y < 32; y++)	// list registers from 0x20-0xff
    {
	printf("   .byte ");
	for (x = 0; x < 8; x++)
	{
	    printf("$%02x", YM2151Registers[x + (y * 8)]);
	    if (x < 7)
		printf(",");
	}
	printf(" ;  %02X-%02X  %s", y * 8, ((y + 1) * 8) - 1, RegDescrip[y]);
	printf("\n");
	if (y % 4 == 3)
	    printf("\n");
    }
    printf("\n");

    printf("%s_PatternMatrix\n", AsmName);
    for (patindex = 0; patindex < OurDmfHeader.RowsInPatternMatrix; patindex++)
    {
	printf("  .byte ");
	for (chindex = 0; chindex < FMCHANNELS; chindex++)
	{
	    printf("<%s_%03x,", AsmName, PatternMatrixOut[chindex][patindex]);
	    printf(">%s_%03x", AsmName, PatternMatrixOut[chindex][patindex]);
	    if ((chindex) < (FMCHANNELS - 1))
		printf(", ");	// indent each new row of matrix data
	}
	printf("\n");
    }
    printf("%s_PatternMatrixEnd\n", AsmName);
    printf("\n");


    printf(" ; The data for each of the patterns follows.\n");
    printf(" ; $ff means rest. other values are notes in the YM2151 expected format.\n\n");
    // Finally, output the pattern data
    for (patindex = 0; patindex < GlobalPatternTotal; patindex++)
    {
	printf("%s_%03x\n", AsmName, patindex);
	for (noteindex = 0; noteindex < OurDmfHeader.RowsPerPattern; noteindex++)
	{
	    if ((noteindex % 16) == 0)
		printf("     .byte ");
	    printf("$%02x", PatternsOut[patindex][noteindex]);
	    if ((noteindex % 16) == 15)
		printf("\n");
	    else
		printf(",");
	}
	printf("\n");
    }

    printf("%s_SongEnd\n\n", AsmName);

    printf("  echo \"  *** the %s song data is\",[(%s_SongEnd-%s_Song)]d,\"bytes long.\"\n\n", AsmFileName, AsmName,
	   AsmName);
    printf("  echo \"  *** the xmfm driver size is\",[(xmym_driver_end-xmym_driver_start)]d,\"bytes long.\"\n\n");


}

int FindPattern(void)
{
    int pindex, rindex;

    if (GlobalPatternTotal == 0)
	return (0);

    for (pindex = 0; pindex < GlobalPatternTotal; pindex++)
    {
	for (rindex = 0; rindex < OurDmfHeader.RowsPerPattern; rindex++)
	{
	    if (PatternsOut[pindex][rindex] != PatternsOut[GlobalPatternTotal][rindex])
		break;
	}

	// check if we got here by our end loop condition, if so, this pattern matches the new one...
	if (rindex == OurDmfHeader.RowsPerPattern)
	    return (pindex);
    }
    return (GlobalPatternTotal);
}

int SqueezePatterns(void)
{
    int pindex, rindex;

    // If tick1 != tick2, we can't squeeze...
    if (OurDmfHeader.TickTime1 != OurDmfHeader.TickTime2)
	return (0);

    // If we're using an odd number of RowsPerPattern, we can't squeeze...
    if ((OurDmfHeader.RowsPerPattern & 1) == 1)
	return (0);

    // If we have data on odd rows, we can't squeeze...
    for (pindex = 0; pindex < GlobalPatternTotal; pindex++)
	for (rindex = 0; rindex < OurDmfHeader.RowsPerPattern; rindex = rindex + 2)
	    if (PatternsOut[pindex][rindex + 1] != 255)
		return (0);

    // if we're still here, we can squeeze the pattern without data loss...
    // change the ticks, the pattern row count, and squeeze the patterns

    OurDmfHeader.TickTime1 = OurDmfHeader.TickTime1 * 2;
    OurDmfHeader.TickTime2 = OurDmfHeader.TickTime2 * 2;
    OurDmfHeader.RowsPerPattern = OurDmfHeader.RowsPerPattern / 2;

    for (pindex = 0; pindex < GlobalPatternTotal; pindex++)
	for (rindex = 0; rindex < OurDmfHeader.RowsPerPattern; rindex++)
	    PatternsOut[pindex][rindex] = PatternsOut[pindex][rindex * 2];
    return (1);

}


void usage(char *programname)
{
    fprintf(stderr, "%s %s %s\n", PROGNAME, __DATE__, __TIME__);
    fprintf(stderr, "Usage: %s -i INPUTFILE [-o OUTFORMAT]\n", programname);
    fprintf(stderr, "       where INPUTFILE  is the deflemask DMF file to read.\n");
    fprintf(stderr, "       where OUTPUTFILE is the assembly file to create.\n");
    fprintf(stderr, "       if an output file isn't provided, console output will be used.\n");
    fprintf(stderr, "\n");
}
