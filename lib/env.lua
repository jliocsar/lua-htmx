local IS_DEV <const> = os.getenv("DEV") ~= nil

return {
    IS_DEV = IS_DEV
}
