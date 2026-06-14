import { useState } from 'react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import migrationUtils from '../../utils/migrationUtils'

export default function MigrationToolPage() {
  const [isRunning, setIsRunning] = useState(false)
  const [results, setResults] = useState(null)
  const [logs, setLogs] = useState([])

  const addLog = (message) => {
    setLogs(prev => [...prev, { timestamp: new Date().toISOString(), message }])
  }

  const handleRunMigration = async () => {
    if (isRunning) return
    if (!window.confirm('This will scan and repair all products and categories. Continue?')) return

    setIsRunning(true)
    setLogs([])
    setResults(null)

    try {
      addLog('Starting migration...')
      const result = await migrationUtils.runCompleteMigration()
      setResults(result)
      addLog('Migration completed successfully!')
      toast.success('Migration completed!')
    } catch (error) {
      addLog(`Error: ${error.message}`)
      toast.error(`Migration failed: ${error.message}`)
    } finally {
      setIsRunning(false)
    }
  }

  const handleVerify = async () => {
    try {
      addLog('Verifying results...')
      const report = await migrationUtils.verifyMigrationResults()
      setResults(report)
      toast.success('Verification complete!')
    } catch (error) {
      toast.error(`Verification failed: ${error.message}`)
    }
  }

  const handleScanProducts = async () => {
    try {
      addLog('Scanning products...')
      const { products, categoryDistribution } = await migrationUtils.scanProducts()
      setResults({ products: products.length, distribution: categoryDistribution })
      toast.success(`Found ${products.length} products`)
    } catch (error) {
      toast.error(`Scan failed: ${error.message}`)
    }
  }

  const handleScanCategories = async () => {
    try {
      addLog('Scanning categories...')
      const categories = await migrationUtils.scanCategories()
      setResults({ categories: categories.map(c => ({ id: c.id, name: c.name, count: c.productCount })) })
      toast.success(`Found ${categories.length} categories`)
    } catch (error) {
      toast.error(`Scan failed: ${error.message}`)
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Migration Tool"
        subtitle="Database → Product-Category Relationship Fixer"
      />

      <Card>
        <h3 className="mb-4 font-semibold">Migration Actions</h3>
        <div className="grid gap-3 md:grid-cols-2">
          <Button
            onClick={handleRunMigration}
            loading={isRunning}
            className="w-full"
          >
            🔧 Run Complete Migration
          </Button>
          <Button
            onClick={handleVerify}
            variant="secondary"
            className="w-full"
          >
            ✅ Verify Results
          </Button>
          <Button
            onClick={handleScanProducts}
            variant="secondary"
            className="w-full"
          >
            🔍 Scan Products
          </Button>
          <Button
            onClick={handleScanCategories}
            variant="secondary"
            className="w-full"
          >
            🔍 Scan Categories
          </Button>
        </div>
      </Card>

      {results && (
        <Card>
          <h3 className="mb-4 font-semibold">Results</h3>
          <div className="space-y-2 overflow-auto bg-gray-50 rounded p-4">
            <pre className="text-xs whitespace-pre-wrap">
              {JSON.stringify(results, null, 2)}
            </pre>
          </div>
        </Card>
      )}

      {logs.length > 0 && (
        <Card>
          <h3 className="mb-4 font-semibold">Migration Logs</h3>
          <div className="space-y-2 max-h-96 overflow-y-auto bg-gray-900 text-gray-100 rounded p-4 font-mono text-xs">
            {logs.map((log, i) => (
              <div key={i} className="whitespace-pre-wrap">
                <span className="text-gray-500">[{log.timestamp}]</span> {log.message}
              </div>
            ))}
          </div>
        </Card>
      )}

      <Card>
        <h3 className="mb-4 font-semibold">Instructions</h3>
        <ol className="list-decimal space-y-2 ml-5 text-sm">
          <li>Click "Run Complete Migration" to scan products and categories</li>
          <li>The tool will:
            <ul className="list-disc ml-5 space-y-1 mt-1">
              <li>Repair any products with incorrect category format</li>
              <li>Recalculate product counts for all categories</li>
              <li>Update category documents in Firestore</li>
            </ul>
          </li>
          <li>Click "Verify Results" to confirm all counts are correct</li>
          <li>Safe to run multiple times - only updates what has changed</li>
        </ol>
      </Card>
    </div>
  )
}
