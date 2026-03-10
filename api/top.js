// api/top.js
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_KEY
)

export default async function handler(req, res) {
    const { data } = await supabase
        .from('bets')
        .select('user_id, user_name, user_avatar, amount')
    
    const stats = {}
    data.forEach(bet => {
        if (!stats[bet.user_id]) {
            stats[bet.user_id] = {
                id: bet.user_id,
                name: bet.user_name,
                avatar: bet.user_avatar,
                total: 0,
                count: 0
            }
        }
        stats[bet.user_id].total += bet.amount
        stats[bet.user_id].count++
    })
    
    const top = Object.values(stats)
        .sort((a, b) => b.total - a.total)
        .slice(0, 50)
    
    res.json(top)
}
