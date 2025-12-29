Deno.serve(async (req) => {
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE, PATCH',
        'Access-Control-Max-Age': '86400',
        'Access-Control-Allow-Credentials': 'false'
    };

    if (req.method === 'OPTIONS') {
        return new Response(null, { status: 200, headers: corsHeaders });
    }

    try {
        // Get request body
        const body = await req.json();
        const userId = body.userId || null; // Optional: specific user ID

        // Get environment variables
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        const supabaseUrl = Deno.env.get('SUPABASE_URL');

        if (!serviceRoleKey || !supabaseUrl) {
            throw new Error('Supabase configuration missing');
        }

        // Get authorization token from request header
        const authHeader = req.headers.get('authorization');
        if (!authHeader) {
            throw new Error('No authorization header');
        }

        const token = authHeader.replace('Bearer ', '');

        // Verify requester is authenticated and get their ID
        const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'apikey': serviceRoleKey
            }
        });

        if (!userResponse.ok) {
            throw new Error('Invalid token or unauthorized');
        }

        const userData = await userResponse.json();
        const requesterId = userData.id;

        // Determine which user profile to fetch
        const targetUserId = userId || requesterId;

        // If requesting another user's profile, verify requester is admin
        if (userId && userId !== requesterId) {
            const requesterProfileResponse = await fetch(
                `${supabaseUrl}/rest/v1/profiles?id=eq.${requesterId}&select=role`,
                {
                    headers: {
                        'Authorization': `Bearer ${serviceRoleKey}`,
                        'apikey': serviceRoleKey,
                        'Content-Type': 'application/json'
                    }
                }
            );

            if (!requesterProfileResponse.ok) {
                throw new Error('Failed to verify requester profile');
            }

            const requesterProfile = await requesterProfileResponse.json();
            
            if (!requesterProfile || requesterProfile.length === 0 || 
                !['admin', 'super_admin'].includes(requesterProfile[0].role)) {
                throw new Error('Only admins can view other user profiles');
            }
        }

        // Fetch the target user's profile
        const profileResponse = await fetch(
            `${supabaseUrl}/rest/v1/profiles?id=eq.${targetUserId}`,
            {
                headers: {
                    'Authorization': `Bearer ${serviceRoleKey}`,
                    'apikey': serviceRoleKey,
                    'Content-Type': 'application/json'
                }
            }
        );

        if (!profileResponse.ok) {
            const errorText = await profileResponse.text();
            throw new Error(`Failed to fetch profile: ${errorText}`);
        }

        const profileData = await profileResponse.json();

        if (!profileData || profileData.length === 0) {
            throw new Error('Profile not found');
        }

        return new Response(JSON.stringify({
            data: {
                profile: profileData[0]
            }
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });

    } catch (error) {
        console.error('Get user profile error:', error);

        const errorResponse = {
            error: {
                code: 'GET_PROFILE_FAILED',
                message: error.message
            }
        };

        return new Response(JSON.stringify(errorResponse), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
    }
});
