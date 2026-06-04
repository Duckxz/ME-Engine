import std.mem;

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

MEObject root @ 0x0;