local MutationConfig = {
    -- Island States Configuration
    States = {
        Normal = { RiskLevel = "Low" },
        Jungle = { RiskLevel = "Medium" },
        Lava = { RiskLevel = "Extreme", Damage = 5, Tick = 2 },
        Frozen = { RiskLevel = "High", WalkSpeed = 10, DefaultWalkSpeed = 16 },
        Toxic = { RiskLevel = "Extreme", Buffs = {"SpeedBoost", "JumpBoost"} }
    },
    
    -- Buff Mutations Configuration
    Mutations = {
        SpeedBoost = { Amount = 10 },
        JumpBoost = { Amount = 30 }
    }
}

return MutationConfig
