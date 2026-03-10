// api/bet.js
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_KEY
)

export default async function handler(req, res) {
    if (req.method === 'POST') {
        const { userId, amount } = req.body
        
        const { data: user } = await supabase
            .from('users')
            .select('*')
            .eq('id', userId)
            .single()
        
        if (!user || user.balance < amount) {
            return res.status(400).json({ error: 'Недостаточно средств' })
        }
        
        await supabase
            .from('users')
            .update({ 
                balance: user.balance - amount,
                total_sent: user.total_sent + amount
            })
            .eq('id', userId)
        
        await supabase
            .from('bets')
            .insert([{
                user_id: userId,
                user_name: user.name,
                user_avatar: user.avatar,
                amount: amount
            }])
        
        res.json({ success: true })
    }
}
