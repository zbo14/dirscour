#!/usr/bin/env node

'use strict'

const fs = require('fs')
const path = require('path')

const id = process.argv[2]
const lockfile = path.join(__dirname, 'tmp', 'lock')

const run = async () => {
  while (true) {
    try {
      await fs.promises.writeFile(lockfile, id, { flag: 'wx' })
      process.exit()
    } catch {
      await new Promise(resolve => {
        try {
          fs.watch(lockfile, eventType => {
            eventType === 'rename' && resolve()
          })
        } catch {
          resolve()
        }
      })
    }
  }
}

run()
