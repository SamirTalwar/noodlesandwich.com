module.exports = {
  decallbackify: func => (...args) =>
    new Promise(resolve => {
      func(...args, resolve)
    }),

  denodeify: func => (...args) =>
    new Promise((resolve, reject) => {
      func(...args, (error, value) => {
        if (error) {
          reject(error)
        } else {
          resolve(value)
        }
      })
    }),
}
