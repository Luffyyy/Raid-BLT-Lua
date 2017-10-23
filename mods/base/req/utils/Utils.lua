function mrotation.copy(rot)
    if rot then
        return Rotation(rot:yaw(), rot:pitch(), rot:roll())
    end
    return Rotation()
end

function mrotation.set_yaw(rot, yaw)
    return mrotation.set_yaw_pitch_roll(rot, yaw, rot:pitch(), rot:roll())
end

function mrotation.set_pitch(rot, pitch)
    return mrotation.set_yaw_pitch_roll(rot, rot:yaw(), pitch, rot:roll())
end

function mrotation.set_roll(rot, roll)
    return mrotation.set_yaw_pitch_roll(rot, rot:yaw(), rot:pitch(), roll)
end