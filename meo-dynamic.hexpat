import std.mem;

using MEObject;

struct MEProp
{
    char field[4];
    u8 unk0;
    u8 unk1;
    u8 unk2;
    u8 size;
    
    if (std::mem::read_string(addressof(field), 4) == "VTXB") {
        u8 value[while(($ < sizeof($)) && (std::mem::read_string($, 4) != "VTIB"))];
    } else if (std::mem::read_string(addressof(field), 4) == "VTIB") {
        u8 value[while(($ < sizeof($)) && (std::mem::read_string($, 4) != "FORM"))];
    } else if (size == 1) {
        u8 value;
    } else if (size == 2) {
        u16 value;
    } else if (size == 4) {
        u32 value;
    } else {
        u8 values[size];
    }
};

struct MEForm
{
    char id[4];
    u8 unk0;
    u8 unk1;
    u8 count;
    u8 unk2;
    char formType[4];
    
    MEObject nested[count];
};

struct MEObject
{
    if (std::mem::read_string($, 4) == "FORM") {
        MEForm form;
    } else {
        MEProp prop;
    }
};

MEObject root @ 0x0;