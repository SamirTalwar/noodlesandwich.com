module.exports = when => {
  const cache = new Map()
  return {
    get (description, behaviour) {
      return function*(...args) {
        if (!when) {
          return yield behaviour.apply(this, args)
        }

        const key = {description: description, arguments: args}
        const keyString = JSON.stringify(key)
        let value = cache.get(keyString)
        if (value == null) {
          console.log(JSON.stringify({
            cacheMiss: key
          }))
          value = yield behaviour.apply(this, args)
          cache.set(keyString, value)
        }
        return value
      }
    }
  }
}
