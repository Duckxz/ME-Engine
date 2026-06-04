import std.mem;
import std.io;

using MEObject;

struct MEPropHeader
{
    char field[4];
    u8 unk0;
    u8 unk1;
    u8 unk2;
    u8 size;
};

struct MEProp
{
    MEPropHeader Header;

    if (std::mem::read_string(addressof(Header.field), 4) == "VTXB") {
        // Ugly hack for the nonsensical VTXB prop
        u8 unk0; // <- seems to be garbage?
        u8 ValueSlice[while(($ < sizeof($)) && (std::mem::read_string($, 4) != "VTIB"))];
    } else if (std::mem::read_string(addressof(Header.field), 4) == "VTIB") {
        // Even uglier hack for the even more nonsensical VTIB prop
        u8 unk0; // <- also garbage?
        u8 unk1;
        u16 ValueSlice[while(($ < sizeof($)) && (std::mem::read_string($, 4) != "FORM"))];
    } else if (Header.size > 0) {
        match (Header.size) {
            (1): u8 Value;
            (2): u16 Value;
            (4): u32 Value;
            (_): u8 ValueSlice[Header.size];
        }
    }
};

struct METypedProp<T>
{
    MEPropHeader Header;
    T Value;
};

struct MEFormHeader
{
    char id[4];
    u8 unk0;
    u8 unk1;
    u8 count;
    u8 unk2;
    char formType[4];
};

struct METypedForm<T>
{
    MEFormHeader Header;
    T;
};

struct MEColor
{
    u8 R;
    u8 G;
    u8 B;
    u8 A;
};

struct MEMaterial
{
    MEProp AlphaColor;
    MEProp DiffuseColor;
    MEProp SpecularColor;
    MEProp SpecularLevel;
    MEProp Glossiness;
    MEProp AnimatedTexture;
    MEProp LGT1;
    MEProp LGTA;
    MEProp Texture;
    MEProp AlphaTexture;
    MEProp TEXE;
    MEProp Alpha;
    MEProp Reflection;
    MEProp Mips;
    MEProp ZRead;
    MEProp ZWrite;
    MEProp AlphaTest;
    MEProp ATVL;
    MEProp Wind;
    MEProp SMOO;
    MEProp DFOG;
};

struct MEMesh
{
    METypedForm<MEMaterial> Material;
    MEProp VertexBuffer;
    MEProp IndiceBuffer;
};

struct MESModel
{
    MEProp Name;
    METypedForm<MEMesh> Mesh;
};

struct MEModel
{
    MEProp Prop;
    METypedForm<MESModel> SModel;
};

struct MESection
{
    MEProp SECD;
    METypedForm<MEModel> Model;
};

struct MELevel
{
    METypedForm<MESection> Section[2];
};

// The assumption is that MEO and binary IFFs begin with a FORM
struct MEObject
{
    MEFormHeader Header;

    // Just in case they export other types of data in a MEO
    match (std::mem::read_string(addressof(Header.formType), 4))
    {
        ("MDL "): METypedForm<MEModel>    Model    @ 0x0;
        ("SMDL"): METypedForm<MESModel>   SModel   @ 0x0;
        ("MESH"): METypedForm<MEMesh>     Mesh     @ 0x0;
        ("MATR"): METypedForm<MEMaterial> Material @ 0x0;
        ("LVL "): METypedForm<MELevel>    Level    @ 0x0;
    }
};

fn HasNextForm(u128 ptr)
{
    if (ptr + 4 >= sizeof($)) {
        return false;
    }
    
    char next[4] @ ptr;
    return next == "FORM";
};

MEObject root @ 0x0;

/*
Known prop types:
LKID: Link ID
LINK: Link
EHLP
MAPR
DESC: Description
AISC
UJOY
DIFF
STSC
WAYP
PKUP
LAPS: Number of LAPS, 1 int
STRN; (Motor) STRENgth? contains 3 floats
BOW : May be literal bow of the boat? contains 3 floats
CHAM
TRHI
TOBE
LABE
BTIM
SKY : SKY texture, links to BMP
BOOK
WFN 
BBFN
ÇBFN
LVFN
CHOB: CHaracter OBject? links to a character model meo
MNOB: MeNu Object, specifies location and meo file for this object
GMOB: GaMeOBject? links to bct file with a BTCL
STFNP: Scene Stage FileName, links to an iff stage
SCFN: SCene FileName, links to an iff scene
ANIM: Contains a string indicating a layer, then 5 floats
STRT: STaRTing Position, 4 flaots
CPLC
CPLG
CPLS
PPNT
PELE
MSND: <otor SouND, links to a wav
MAXV: MAX Volume?
MPOW: Max POWer? Contains an int
STAN: Contains a single float
MPOS: Motor POSition?, contains 6 floats
HELP
PLYR
HIGH
STAG: STAGe
SCEN
WPCL
BTCL: Something to define boats
FAKF
FLCL: Some kind of form, has a name which links to a boat meo and then a PHYS form
WTCL: Something for the water
BBND
CBND
SECD
SECT
LVL 
GTLI: Game Track List Item? Contains multiple GTRK, check GameInfo.iff
GTRK: Game TRacK
GCHL: Seems to be for championship levels? Also contains GCLI and GCUL to indicate which characters appear as NPCs
GCHM: evel entry for GCHL
EEGG
SSEE: SightSEEing, contains GCHM entries
GCUL: Game Character Unlocked List? check GameInfo.iff more thourougly
GCLI: Game Character List Item
GCHR: Game Character
GINF: GameInfo, contains character and level selection items
TEXF: TEXture Format (dimension?)? 2 ints
DFOG: Diffuse FOG? 1 int
SMOO: SMOOthness? 1 float
WIND: No idea, 1 int
ATVl: Alpha something? 1 foat
ATES: Alpha test? 1 int / bool
MIPS: MIPmapS count? 1 int
REFL: REFLectiveness? 1 int
LGTA
LGT1
ANIT: No idea, 4 ints
ECOL: Ending COLor? 2 RGBA
MCOL: Middle COLor? 3 RGBA
SCOL: Starting/Specular COLor? seems to be 3 RGBA. Reused in MATR
ESZE: End SiZE? two floats
MSZE: Middle SiZE? 5 floats
SSZE: Starting SiZE? two floats
RSPD:No idea, three ints
LINEL No idea, two ints
ACCL: ACCeLeration? 3 ints
ISPD: No idea, maybe <Something> Speed?. three ints or floats
PLAN: No idea, two floats
SPEE: SPEEd? two ints
SPRD: SPReaD? two floats
LIFE: Length of LIFE, two floats
EMIS: EMISsive strength? 1 int
DEST: No idea, 2 ints
SPRG
FLAR: FLARe, 2 floats, 1 RGBA, 1 int (may be index into flare material array)
DMP 
CDMP: C? DaMPening? 2 floats
FRIC: FRICtion? 6 ints
ELAS: ELASticity? 1 float
MASS: MASS, 1 int
DIM : Physical DIMension, 3 floats
SPHT: Seems to be a composite shape? contains one or more of itselves and eventually a SPHR
SPHR: SPHeRe? Contains 3 float values
ZWR : ZWRite? 1 int / bool
ZRD : ZReadD? 1 int / bool
ALPH: ALPHa? single int
TEXE: TEXture Emissive? 1 int
TEXA: TEXture Alpha? links to something
TEX : TEXture, links to BMP
GLOS: GLOSsiness? 1 int
SLVL: Specular LeVeL? 1 int
DCOL: Diffuse COLor? RGBA
ACOL: No idea, some color, RGBA
PROP: Unknown, contains 3 number values in plaintext GameInfo.iff
ITEM
LIST
NAME: Name field
TDBE
PTCL: ParTiCLe?
AUSS: AUDIO SongS? has multiple ITEM entries that link to a wav and have two floats
AUST
3DST
LENS: LENS Flare, contains multiple materials (Engine renders each ontop of eachother?)
DIRL: DIRectional Light, 1 RGBA, 4 float
AMBL: AMBient Light? 1 RGBA, 1 float (may be strength?)
FOG : FOG, 1 bool, 1 RGBA, 3 floats
PHYS: PHYSics settings
SPLN: SPLiNe?
VTIB
VTXB
MATR
MESH
SMDL
MDL 
MENU: MENU description, found in mnu files, not a form, contains an ITEMS with multiple ITEM entries with 1 int, a string, a lik  to a meo and a signedint
ITEMS: Contain one or mores ITEM entries
*/