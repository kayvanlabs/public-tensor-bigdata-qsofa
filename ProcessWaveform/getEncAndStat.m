function [enc, stat] = getEncAndStat(instr)
    if contains(instr, "OOB")
        enc = convertNumToStrEnc(extract(instr, digitsPattern));
        stat = "Out of bounds";
    elseif contains(instr, "Missing")
        enc = convertNumToStrEnc(extract(instr, digitsPattern));
        stat = "Missing signals";
    else
        enc = instr;
        stat = "";
    end
end

function encstr = convertNumToStrEnc(encNum)
    encNumeric = str2double(encNum);
    if encNumeric < 10
        encstr = strcat("00", encNum);
    elseif encNumeric < 100
        encstr = strcat("0", encNum);
    else
        encstr = encNum;
    end
end

