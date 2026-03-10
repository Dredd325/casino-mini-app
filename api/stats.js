// api/stats.js
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_KEY
)

export default async function handler(req, res) {
    const [pool, royalty, players] = await Promise.all([
        supabase.from('settings').select('value').eq('key', 'total_pool').single(),
        supabase.from('settings').select('value').eq('key', 'total_royalty').single(),
        supabase.from('users').select('count', { count: 'exact' })
    ])
    
    res.json({
        totalSent: parseFloat(pool.data?.value || 0),
        totalRoyalty: parseFloat(royalty.data?.value || 0),
        totalPlayers: players.count || 0
    })
}
