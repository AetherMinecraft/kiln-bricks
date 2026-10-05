import assert from "node:assert/strict"
import { readFile, readdir } from "node:fs/promises"
import { test } from "node:test"
import Ajv2020 from "ajv/dist/2020.js"
import addFormats from "ajv-formats"
import { parse } from "yaml"

const schemaRoot =
  "https://raw.githubusercontent.com/kiln-site/kiln/b4c2cf74be69fe345a1576fdca0e027d16994e76/apps/bricks/schema/"
const ajv = new Ajv2020({ allErrors: true, strict: true })
addFormats(ajv)

async function schema(name) {
  const response = await fetch(new URL(name, schemaRoot), {
    signal: AbortSignal.timeout(30_000),
  })
  assert.ok(response.ok, `Could not load ${name}: HTTP ${response.status}`)
  return response.json()
}

test("the catalog and its recipes satisfy Kiln's v1 contracts", async () => {
  const [catalogSchema, recipeSchema] = await Promise.all([
    schema("catalog-v1.schema.json"),
    schema("recipe-v1.schema.json"),
  ])
  const validateCatalog = ajv.compile(catalogSchema)
  const validateRecipe = ajv.compile(recipeSchema)
  const catalog = parse(
    await readFile(new URL("../catalog.yml", import.meta.url), "utf8")
  )
  assert.ok(validateCatalog(catalog), ajv.errorsText(validateCatalog.errors))
  const recipeFiles = (await readdir(new URL("../recipes/", import.meta.url)))
    .filter((name) => name.endsWith(".yml"))
    .map((name) => `recipes/${name}`)
    .sort()
  assert.deepEqual([...catalog.recipes].sort(), recipeFiles)

  const ids = new Set()
  for (const path of catalog.recipes) {
    const recipe = parse(
      await readFile(new URL(`../${path}`, import.meta.url), "utf8")
    )
    assert.ok(
      validateRecipe(recipe),
      `${path}: ${ajv.errorsText(validateRecipe.errors)}`
    )
    assert.ok(
      !ids.has(recipe.metadata.id),
      `Duplicate Brick: ${recipe.metadata.id}`
    )
    ids.add(recipe.metadata.id)
    assert.ok(
      recipe.network.ports.some(
        ({ name }) => name === recipe.network.primaryPort
      )
    )
    for (const [name, variable] of Object.entries(recipe.variables)) {
      if ("default" in variable) {
        assert.equal(
          typeof variable.default,
          variable.type,
          `${path}: ${name}.default`
        )
        if (variable.rules?.pattern) {
          assert.match(
            variable.default,
            new RegExp(variable.rules.pattern),
            `${path}: ${name}.default`
          )
        }
      }
    }
  }
})
