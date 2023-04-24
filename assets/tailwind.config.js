const colors = require('tailwindcss/colors')

module.exports = {
  mode: 'jit',
  purge: [
    './js/**/*.js',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {
      colors: {
        teal: colors.teal
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
