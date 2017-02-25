module.exports = when => {
  const cache = new Map()
  return (description, behaviour) => {
    return async (...args) => {
      if (!when) {
        return await behaviour(...args)
      }

      const key = {description: description, arguments: args}
      const keyString = JSON.stringify(key)
      let value = cache.get(keyString)
      if (value == null) {
        console.log(JSON.stringify({
          cacheMiss: key
        }))
        value = await behaviour(...args)
        cache.set(keyString, value)
      }
      return value
    }
  }
}
