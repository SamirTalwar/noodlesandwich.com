module.exports = (log, when) => {
  const cache = new Map()
  return (description, behaviour) => async (...args) => {
    if (!when) {
      return behaviour(...args)
    }

    const key = {description, arguments: args}
    const keyString = JSON.stringify(key)
    let value = cache.get(keyString)
    if (value == null) {
      log(
        JSON.stringify({
          cacheMiss: key,
        }),
      )
      value = await behaviour(...args)
      cache.set(keyString, value)
    }
    return value
  }
}
