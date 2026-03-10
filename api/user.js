// api/user.js
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_KEY
)

export default async function handler(req, res) {
    if (req.method === 'POST') {
        const { telegramId, name, avatar } = req.body
        
        let { data: user } = await supabase
            .from('users')
            .select('*')
            .eq('telegram_id', telegramId)
            .single()
        
        if (!user) {
            const { data } = await supabase
                .from('users')
                .insert([{
                    telegram_id: telegramId,
                    name: name,
                    avatar: avatar,
                    balance: 100,
                    total_sent: 0
                }])
                .select()
                .single()
            user = data
        }
        
        res.json(user)
    }
}
